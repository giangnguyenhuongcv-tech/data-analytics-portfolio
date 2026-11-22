---------- Tạo báo cáo -----------
------ bảng 1: Về quy mô tín dụng ------
create proc prc_baocao_tindung
	@ngay_bd date,
	@ngay_kt date
as 
begin
	declare @sokhach_tang int;
	declare @sokhach_giam int;
	declare @dunogoc_giam bigint;
	declare @dunogoc_dk bigint;
	declare @dunogoc_ck bigint;

	set @sokhach_tang = (
		select  count(distinct MA_KHACHHANG)      as 'Số lượng khách hàng'
		from    HOPDONG_TINDUNG
		where   NGAY_GIAINGAN > @ngay_bd
		and     NGAY_GIAINGAN <= @ngay_kt
		and     MA_KHACHHANG not in (
					select MA_KHACHHANG
					from   HOPDONG_TINDUNG
					where  NGAY_GIAINGAN <= @ngay_bd
					and    NGAY_DAOHAN > @ngay_bd
				)
	);

	set @sokhach_giam = (
		select  count(distinct MA_KHACHHANG)      as 'Số lượng khách hàng'
		from    HOPDONG_TINDUNG
		where   NGAY_DAOHAN > @ngay_bd
		and     NGAY_DAOHAN <= @ngay_kt
		and     MA_KHACHHANG not in (
					select MA_KHACHHANG
					from   HOPDONG_TINDUNG
					where  NGAY_GIAINGAN <= @ngay_kt
					and    NGAY_DAOHAN > @ngay_kt
				)
	);

	set @dunogoc_giam = (
		select   sum(TRAGOC)         as DU_NO_GOC_CONLAI
		from     KHACHHANG_TRANO
		where    NGAYTRA <= @ngay_kt
		and      NGAYTRA > @ngay_bd
	);

	--------- so du no goc da tra / con lai ---------
	with cte_bd as (
		select   MA_HOPDONG_TINDUNG,
				     sum(TRAGOC)         as TIEN_TRA_NO_GOC
		from     KHACHHANG_TRANO
		where    NGAYTRA <= @ngay_bd
		group by MA_HOPDONG_TINDUNG
	),
	cte2_bd as (
		select    sum(hd.SOTIEN) - sum(cte_bd.TIEN_TRA_NO_GOC) as DU_NO_GOC_CL
		from      HOPDONG_TINDUNG hd
		left join cte_bd   on cte_bd.MA_HOPDONG_TINDUNG = hd.MA_HOPDONG_TINDUNG
		where	    hd.NGAY_GIAINGAN <=	@ngay_bd
		and		    hd.NGAY_DAOHAN	>	@ngay_bd
	),
	
	cte_kt as (
		select   MA_HOPDONG_TINDUNG,
				     sum(TRAGOC)         as TIEN_TRA_NO_GOC
		from     KHACHHANG_TRANO
		where    NGAYTRA <= @ngay_kt
		group by MA_HOPDONG_TINDUNG
	),
	cte2_kt as (
		select    sum(hd.SOTIEN) - sum(cte_kt.TIEN_TRA_NO_GOC) as DU_NO_GOC_CL
		from      HOPDONG_TINDUNG hd
		left join cte_kt on cte_kt.MA_HOPDONG_TINDUNG = hd.MA_HOPDONG_TINDUNG
		where	    hd.NGAY_GIAINGAN <=	@ngay_kt
		and		    hd.NGAY_DAOHAN	>	@ngay_kt
	)

	select @dunogoc_dk = (select cte2_bd.DU_NO_GOC_CL from cte2_bd),
	       @dunogoc_ck = (select cte2_kt.DU_NO_GOC_CL from cte2_kt);

	---------- đầu kì -----------
	select  convert(nvarchar(10), @ngay_bd, 103)  as 'Tiêu chí',
					count(distinct hd.MA_HOPDONG_TINDUNG) as 'Số hợp đồng tín dụng',
					count(distinct hd.MA_KHACHHANG)       as 'Số lượng khách hàng',
					sum(hd.SOTIEN)                        as 'Tổng giá trị các hợp đồng tín dụng',
					@dunogoc_dk                           as 'Dư nợ gốc còn lại'
	from    HOPDONG_TINDUNG  hd
	where   hd.NGAY_GIAINGAN  <= @ngay_bd
	and     hd.NGAY_DAOHAN > @ngay_bd
	union all

	-------- phát sinh tăng --------
	select N'Phát sinh tăng',
			   count(distinct MA_HOPDONG_TINDUNG) as 'Số hợp đồng tín dụng',
			   @sokhach_tang                      as 'Số lượng khách hàng',
			   sum(SOTIEN)                        as 'Tổng giá trị các hợp đồng tín dụng',
			   sum(SOTIEN)                        as 'Dư nợ gốc còn lại'
	from   HOPDONG_TINDUNG
	where  NGAY_GIAINGAN > @ngay_bd
	and    NGAY_GIAINGAN <= @ngay_kt
	union all

	-------- phát sinh giảm --------
	select N'Phát sinh giảm',
			   count(distinct hd.MA_HOPDONG_TINDUNG) as 'Số hợp đồng tín dụng',
			   @sokhach_giam                         as 'Số lượng khách hàng',
			   sum(hd.SOTIEN)                        as 'Tổng giá trị các hợp đồng tín dụng',
			   @dunogoc_giam                         as 'Dư nợ gốc còn lại'
	from   HOPDONG_TINDUNG hd 
	where  NGAY_DAOHAN > @ngay_bd
	and    NGAY_DAOHAN <= @ngay_kt
	union all

	-------- cuối kì -------- 
	select  convert(nvarchar(10), @ngay_kt, 103),
					count(distinct hd.MA_HOPDONG_TINDUNG) as 'Số hợp đồng tín dụng',
					count(distinct hd.MA_KHACHHANG)       as 'Số lượng khách hàng',
					sum(hd.SOTIEN)                        as 'Tổng giá trị các hợp đồng tín dụng',
					@dunogoc_ck                           as 'Dư nợ gốc còn lại'
	from    HOPDONG_TINDUNG  hd
	where   NGAY_GIAINGAN  <= @ngay_kt
	and     NGAY_DAOHAN > @ngay_kt
end;

exec prc_baocao_tindung  '2023-12-31', '2024-06-30';
----- bảng 2: Hợp đồng tín dụng trọng điểm -----
create proc prc_max_hdtd
	@ngay_bd date,
	@ngay_kt date
as
begin
	with sort_hdtd as (
		select   MA_HOPDONG_TINDUNG,
						 SOTIEN,
						 LAISUAT,
						 rank() over (order by SOTIEN desc) as 'STT'
		from     HOPDONG_TINDUNG
		where    NGAY_GIAINGAN between @ngay_bd and @ngay_kt
	)
	select   kh.TEN_KHACHHANG    as 'Tên khách hàng',
					 kh.MA_KHACHHANG     as 'Mã khách hàng',
					 cn.TEN_CHINHANH     as 'Chi nhánh',
					 s.SOTIEN            as 'Số tiền giải ngân',
					 s.LAISUAT           as 'Lãi suất'
	from     sort_hdtd       s
	join     HOPDONG_TINDUNG hd on s.MA_HOPDONG_TINDUNG = hd.MA_HOPDONG_TINDUNG
	join     KHACHHANG       kh on hd.MA_KHACHHANG      = kh.MA_KHACHHANG
	join     CHINHANH        cn on cn.MA_CHINHANH       = kh.MA_CHINHANH
	where    s.STT <= 3
	order by s.STT;
end;

exec prc_max_hdtd '2024-01-01', '2024-06-30';
----- bảng 3: Thu hồi nợ năm 2024 -----
create proc prc_thn 
	@nam int
as
begin
	----- Quý 1 -----
	select N'Quý 1',
			   sum(TRAGOC)                as 'Số tiền gốc đã thu',
			   sum(TRALAI)                as 'Số tiền lãi thu',
			   sum(TRAGOC) + sum(TRALAI)  as 'Tổng'
	from   KHACHHANG_TRANO
	where  year(NGAYTRA) = @nam 
	and    datepart(quarter, NGAYTRA) = 1
	union all
	
	----- Quý 2 -----
	select N'Quý 2',
			   sum(TRAGOC)                as 'Số tiền gốc đã thu',
			   sum(TRALAI)                as 'Số tiền lãi thu',
			   sum(TRAGOC) + sum(TRALAI)  as 'Tổng'
	from   KHACHHANG_TRANO
	where  year(NGAYTRA) = @nam 
	and    datepart(quarter, NGAYTRA) = 2
	union all

  ----- Quý 3 -----
	select N'Quý 3',
			   sum(TRAGOC)                as 'Số tiền gốc đã thu',
			   sum(TRALAI)                as 'Số tiền lãi thu',
			   sum(TRAGOC) + sum(TRALAI)  as 'Tổng'
	from   KHACHHANG_TRANO
	where  year(NGAYTRA) = @nam 
	and    datepart(quarter, NGAYTRA) = 3
	union all

  ----- Quý 4 -----
	select N'Quý 4',
			   sum(TRAGOC)                as 'Số tiền gốc đã thu',
			   sum(TRALAI)                as 'Số tiền lãi thu',
			   sum(TRAGOC) + sum(TRALAI)  as 'Tổng'
	from   KHACHHANG_TRANO
	where  year(NGAYTRA) = @nam 
	and    datepart(quarter, NGAYTRA) = 4
	union all

	select N'Cả năm',
			   sum(TRAGOC)                as 'Số tiền gốc đã thu',
			   sum(TRALAI)                as 'Số tiền lãi thu',
			   sum(TRAGOC) + sum(TRALAI)  as 'Tổng'
	from   KHACHHANG_TRANO
	where  year(NGAYTRA) = @nam 
end;

exec prc_thn 2024;
----- bảng 4: Lãi suất -----
create proc prc_lsbq
	@nam int
as
begin
	select  concat(N'Từ ', @nam -4, N' về trước') as 'Tiêu chí',
					cast(round((sum(SOTIEN*LAISUAT*0.01) / sum(SOTIEN))*100, 4) as decimal(10, 4)) as 'Lãi suất cho vay bình quân (%)' 
	from    HOPDONG_TINDUNG
	where   year(NGAY_GIAINGAN) <= (@nam - 4)
	union all

	select  cast((@nam - 3) as varchar(20)),
			    cast(round((sum(SOTIEN*LAISUAT*0.01) / sum(SOTIEN))*100, 4) as decimal(10, 4)) as 'Lãi suất cho vay bình quân (%)' 
	from    HOPDONG_TINDUNG
	where   year(NGAY_GIAINGAN) = (@nam - 3)
	union all

	select  cast((@nam - 2) as varchar(20)),
			    cast(round((sum(SOTIEN*LAISUAT*0.01) / sum(SOTIEN))*100, 4) as decimal(10, 4)) as 'Lãi suất cho vay bình quân (%)' 
	from    HOPDONG_TINDUNG
	where   year(NGAY_GIAINGAN) = (@nam - 2)
	union all

	select  cast((@nam - 1) as varchar(20)),
			    cast(round((sum(SOTIEN*LAISUAT*0.01) / sum(SOTIEN))*100, 4) as decimal(10, 4)) as 'Lãi suất cho vay bình quân (%)' 
	from    HOPDONG_TINDUNG
	where   year(NGAY_GIAINGAN) = (@nam - 1)
	union all

	select  cast(@nam as varchar(20)),
			    cast(round((sum(SOTIEN*LAISUAT*0.01) / sum(SOTIEN))*100, 4) as decimal(10, 4)) as 'Lãi suất cho vay bình quân (%)' 
	from    HOPDONG_TINDUNG
	where   year(NGAY_GIAINGAN) = @nam 
end;

exec prc_lsbq 2024;
----- bảng 5: Phân bổ tín dụng theo mạng lưới Chi nhánh -----
create proc prc_baocao_duno_cn
	@ngay_bd date,
	@ngay_kt date
as 
begin
	with tragoc_dk as (
		select   MA_HOPDONG_TINDUNG,
				     sum(TRAGOC) as TIEN_GOC_DA_TRA
		from     KHACHHANG_TRANO
		where    NGAYTRA <= @ngay_bd
		group by MA_HOPDONG_TINDUNG
	)	

	----- đầu kì -----
	select    convert(nvarchar(10), @ngay_bd, 103)                 as 'Tiêu chí',
					  cn.TEN_CHINHANH                                      as 'Tên chi nhánh',
					  sum(hd.SOTIEN) -  sum(isnull(tg.TIEN_GOC_DA_TRA, 0)) as 'Dư nợ tín dụng'
	from      CHINHANH        cn
	left join KHACHHANG       kh on cn.MA_CHINHANH        = kh.MA_CHINHANH
	left join HOPDONG_TINDUNG hd on hd.MA_KHACHHANG       = kh.MA_KHACHHANG
	left join tragoc_dk       tg on tg.MA_HOPDONG_TINDUNG = hd.MA_HOPDONG_TINDUNG
	where     hd.NGAY_GIAINGAN <= @ngay_bd
	and       hd.NGAY_DAOHAN   >  @ngay_bd
	group by  cn.TEN_CHINHANH
	union all

	----- phát sinh tăng ----
	select    N'Phát sinh tăng',
					  cn.TEN_CHINHANH  as 'Tên chi nhánh',
					  sum(isnull(hd.SOTIEN, 0))   as 'Dư nợ tín dụng'
	from      CHINHANH        cn
	left join KHACHHANG       kh on cn.MA_CHINHANH        = kh.MA_CHINHANH
	left join HOPDONG_TINDUNG hd on hd.MA_KHACHHANG       = kh.MA_KHACHHANG
	where     hd.NGAY_GIAINGAN >  @ngay_bd
	and       hd.NGAY_GIAINGAN <= @ngay_kt
	group by  cn.TEN_CHINHANH
	union all
	
	----- phát sinh giảm ----
	select    N'Phát sinh giảm', 
					  cn.TEN_CHINHANH    as 'Tên chi nhánh',
					  sum(TRAGOC)        as 'Dư nợ tín dụng'
	from      CHINHANH        cn 
	left join KHACHHANG       kh on cn.MA_CHINHANH        = kh.MA_CHINHANH
	left join HOPDONG_TINDUNG hd on kh.MA_KHACHHANG       = hd.MA_KHACHHANG
	left join KHACHHANG_TRANO tn on hd.MA_HOPDONG_TINDUNG = tn.MA_HOPDONG_TINDUNG
	where	    tn.NGAYTRA > @ngay_bd
	and       tn.NGAYTRA <= @ngay_kt
	group by  cn.TEN_CHINHANH
	union all

	----- cuối kì -----
	select    convert(nvarchar(10), @ngay_kt, 103),
					  cn.TEN_CHINHANH                                     as 'Tên chi nhánh',
					  sum(hd.SOTIEN) - sum(isnull(tg.TIEN_GOC_DA_TRA, 0)) as 'Dư nợ tín dụng'
	from      CHINHANH        cn
	left join KHACHHANG       kh on cn.MA_CHINHANH        = kh.MA_CHINHANH
	left join HOPDONG_TINDUNG hd on hd.MA_KHACHHANG       = kh.MA_KHACHHANG
	left join (
		select   MA_HOPDONG_TINDUNG,
				     sum(TRAGOC) as TIEN_GOC_DA_TRA
		from     KHACHHANG_TRANO
		where    NGAYTRA <= @ngay_kt
		group by MA_HOPDONG_TINDUNG
	) tg                         on tg.MA_HOPDONG_TINDUNG = hd.MA_HOPDONG_TINDUNG
	where     hd.NGAY_GIAINGAN <= @ngay_kt
	and       hd.NGAY_DAOHAN   >  @ngay_kt
	group by  cn.TEN_CHINHANH

	order by  cn.TEN_CHINHANH
end;

exec prc_baocao_duno_cn '2023-12-31', '2024-06-30';
