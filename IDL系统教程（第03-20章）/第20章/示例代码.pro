;+
;  ��IDL������ơ�
;   -���ݿ��ӻ���ENVI���ο���
;        
; ʾ������
;
; ����: ������
;
; ��ϵ��ʽ��sdlcdyq@sina.com
;-
;
;-��20��ʾ������

ENVI,/Restore_Base_Sav_Files
ENVI_Batch_init

;�Ի���ѡ���ļ�����ͼ20.1
filename = ENVI_PICKFILE(title='Pick a img file',  filter='*.img')
;�鿴ѡ����ļ���
PRINT,filename


;���ļ�
ENVI_OPEN_FILE,filename,r_fid = fid
;ѡ���ļ�����ͼ20.2
ENVI_SELECT, fid=fid,dims=dims,pos=pos
;�鿴ѡ�����Ϣ
PRINT,dims,pos

;��ȡ�Ѿ��򿪵��ļ�ID
ids = ENVI_GET_FILE_IDS()
;���ID
PRINT,ids

;���ļ�
ENVI_OPEN_FILE,filename,r_fid = fid
;�Ƴ��Ѿ��򿪵��ļ�ID
ENVI_FILE_MNG,id = fid,/Remove
;��ȡ�Ѿ��򿪵��ļ�ID
fids = ENVI_GET_FILE_IDS()
;�������
print,fids

;�Ƴ��Ѿ��򿪵��ļ�ID���Ӵ�����ɾ��
ENVI_FILE_MNG,id = fid1,/Remove,/Delete
;�����ļ�id��ѯ�ļ���Ϣ
ENVI_FILE_QUERY,fid, $
  fname = fName, $
  dims = dims, $
  nb = nb , $
  ns = ns , $
  nl = nl , $
  SENSOR_TYPE = SENSOR_TYPE
;�鿴�ļ���ID
print,fid


;�鿴�ļ���
print,fname
C:\Program Files\ITT\IDL\IDL80\products\envi48\data\can_tmr.img
;�鿴�ļ��ռ��Ӽ���Χ
print,dims
;�鿴������
print,nb
;�鿴�ļ�����
print,ns
;�鿴�ļ�����
print,nl
;�鿴����������
print,sensor_type

;��ȡ���в��Ρ���20�С�20-40�еĲ������ݣ�
data = envi_get_slice(fid=fid, line=20, pos=lindgen(nb), xs=20, xe=40)
help,data

;��ȡ�ļ��ĵ�һ������������
data = ENVI_GET_DATA(fid=fid, dims=dims, pos=0)
help,data

;��ȡ�ļ��ĵڶ�������������
data = ENVI_GET_DATA(fid=fid, dims=dims, pos=1,XFACTOR =0.5,yFACTOR=0.5)
help,data


;����ȡ�ĵ�һ�����δ洢���ڴ���
ENVI_ENTER_DATA, data, r_fid = rFid

;��ȡENVI�����ò����ṹ��
cfg = envi_get_configuration_values()
;Ĭ�����Ŀ¼
out_path = cfg.DEFAULT_OUTPUT_DIRECTORY
;��������ļ���
out_file = out_path+'tm_band1.img'
;�����Ʒ�ʽ���
OPENW,lun,out_file,/get_lun
WRITEU,lun,data
FREE_LUN,lun
;д���ļ���ͷ�ļ���Ϣ�����ļ���ͼ20.4��
ENVI_SETUP_HEAD, fname=out_file, $
  ns=ns, nl=nl, nb=1, $
  interleave=0, $
  data_type=data_type, $
  offset=0, /write, /open



;�����ļ�����·����
file = 'C:\Program Files\ITT\IDL\IDL80\products\envi48\data\bhtmref.img'
;���ļ�
ENVI_OPEN_FILE,file,r_fid = fid
;��ȡ�ļ���map��Ϣ
mapinfor = ENVI_GET_MAP_INFO(fid = fid, UNDEFINED = uDefined)
;����ļ�������map��Ϣ���������Ϣ��
IF uDefined EQ 1 THEN PRINT,'�ļ�������map_info'
;������Ϣ��鿴map��Ϣ�ṹ��
HELP,mapInfor
;�鿴�ļ�ͶӰ��Ϣ
HELP,mapInfor.PROJ
;����ļ����Ͻǵ���Ϣ
PRINT,mapinfor.MC
;����ļ��ֱ���
PRINT,mapinfor.PS
;��ȡ�ļ�ͶӰ��Ϣ
fileProj = ENVI_GET_PROJECTION(fid = fid)
;�鿴ͶӰ��Ϣ����
HELP,fileProj


;������γ��ͶӰ
proj = ENVI_PROJ_CREATE(/geographic)

;ת����λ
units = ENVI_TRANSLATE_PROJECTION_UNITS('km')
;��������������
datum = 'WGS-84'
;����������ΪWGS-84�Ĵ���Ϊ23���ϰ���UTMͶӰ
Proj = ENVI_PROJ_CREATE(/utm, $
  zone=23, /south, $
  datum=datum, units=units)
;�鿴������ͶӰ�ṹ����Ϣ
HELP,proj

; Define the PARAMS values

;����ͶӰ��������
Params = [6378160.0, 6356774.7, $
  0.000000, 99.000000, $
  500000., 10000000., $
  .9996]

;�������������ƺ�ͶӰ����
datum = 'Australian Geodetic 1966'
name = 'Australian Map Grid (AGD 66) Zone 47'
;����ͶӰ
proj = ENVI_PROJ_CREATE(type=3, $
  name=name, $
  datum=datum, $
  params=params)
;�鿴������ͶӰ�ṹ����Ϣ
HELP,proj

;ͶӰ������Ϣ�ַ���
projcsStr = 'PROJCS["Beijing_1954_GK_Zone_19N",GEOGCS["GCS_Beijing_1954",DATUM["D_Beijing_1954",SPHEROID["Krasovsky_1940",6378245.0,298.3]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Gauss_Kruger"],PARAMETER["False_Easting",
;����ͶӰ��typeΪ42��ʹ��ESRI Projection Engine����ͶӰ
proj = ENVI_PROJ_CREATE(type = 42, $
  pe_coord_sys_str=projcsStr)
;�鿴������ͶӰ�ṹ����Ϣ
HELP,proj


;ͼ�����Ͻǵ�ͼ���������������
;[0.5d,0.5d]�������Ͻǵ�һ�����ص�����
;[-117.4D, 34.5D] ��ʾ��λ�õľ�γ������ֵ
mc = [0.5D, 0.5D, -117.4D, 34.5D]
;ͼ��ķֱ���
ps = [1D/3600, 1D/3600]
;������γ�����꣬Ĭ��ͶӰ���굥λ�Ƕ�
map_info = ENVI_MAP_INFO_CREATE($
  /geographic, $
  mc=mc, ps=ps)
;�鿴�����ĵ�������ṹ����Ϣ
HELP,map_info

;ת��km��λ��ʶ
units = ENVI_TRANSLATE_PROJECTION_UNITS('km')
;��������������
datum = 'North America 1983'
;�������Ͻǵ������������������
mc = [0D, 0, 177246, 8339330]
;�ֱ���Ϊ0.03km=30m
ps=[0.03, 0.03]
; ����ͶӰ
map_info = ENVI_MAP_INFO_CREATE($
  /UTM, ZONE=23, /SOUT, $
  DATUM = datum, UNITS = units, $
  MC = mc, PS = ps)
;�鿴�����ĵ�������ṹ����Ϣ
HELP,map_info

END