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

;ENVI�´���evf��ʾ������
;
PRO USING_ENVI_Create_EVF
  COMPILE_OPT IDL2
  ;������γ��ͶӰ
  proj = ENVI_PROJ_CREATE(/geographic)
  ;���徭γ����ɢ��
  points = [-106.572, 39.6643, $
    -106.643, 39.5218, $
    -106.453, 39.4386, $
    -106.417, 39.6168, $
    -106.595, 39.4386  ]
  ;�㼯����Ϊ5*2�ĵ�
  points = REFORM(points, 2, 5)
  ;�������߾�γ�ȵ����꼯��
  polyline = [-106.904, 41.5887, $
    -106.821, 42.2302, $
    -106.013, 42.2183, $
    -105.206, 41.3749, $
    -105.657, 40.5078, $
    -105.835, 39.5574, $
    -105.170, 38.8447, $
    -104.125, 39.4862, $
    -103.269, 40.0563, $
    -103.269, 40.0682, $
    -102.913, 39.0585, $
    -102.901, 39.0585, $
    -102.901, 39.0348, $
    -103.210, 38.4289, $
    -103.804, 38.3695]
  ;�㼯����Ϊ15*2�ĵ�
  polyline = REFORM(polyline, 2, 15)
  ;�������ζ������꼯��
  polygon = [-104.113, 41.6956, $
    -103.994, 42.1589, $
    -103.934, 41.6838, $
    -103.471, 41.8738, $
    -103.887, 41.5531, $
    -103.863, 41.0185, $
    -103.851, 41.0185, $
    -104.041, 41.4818, $
    -104.041, 41.4937, $
    -104.552, 41.2680, $
    -104.220, 41.6006, $
    -104.422, 42.0995, $
    -104.113, 41.6956]
  ;�㼯����Ϊ13*2�ĵ�
  polygon = REFORM(polygon, 2, 13)
  
  ;��ʼ������evf
  evf_ptr = ENVI_EVF_DEFINE_INIT('c:\temp\sample.evf', $
    projection=proj, data_type=4, $
    layer_name='Sample EVF File')
  ;����ʧ���򷵻�
  IF (PTR_VALID(evf_ptr) EQ 0) THEN RETURN
  ;�����ɢ���¼
  FOR i=0,4 DO ENVI_EVF_DEFINE_ADD_RECORD, evf_ptr, points[*,i]
  ;������߼�¼
  ENVI_EVF_DEFINE_ADD_RECORD, evf_ptr, polyline
  ;��Ӷ���μ�¼
  ENVI_EVF_DEFINE_ADD_RECORD, evf_ptr, polygon
  
  ;EVF�ļ�������ϣ��ر��ļ�
  evf_id = ENVI_EVF_DEFINE_CLOSE(evf_ptr, /return_id)
  ENVI_EVF_CLOSE, evf_id
  ;���������ļ�,1-5Ϊ���ļ�,6Ϊ����,7Ϊ�����
  attributes = REPLICATE( {name:'', id:0L}, 7)
  FOR i=0,4 DO BEGIN
    attributes[i].NAME = 'Sample Point ' + STRTRIM(i+1,2)
    attributes[i].ID = i+1
  ENDFOR
  attributes[5].NAME = 'Sample Polyline'
  attributes[5].ID = 6
  attributes[6].NAME = 'Sample Polygon'
  attributes[6].ID = 7
  ;д��ʸ�������ļ�
  ENVI_WRITE_DBF_FILE, 'c:\temp\sample.dbf', attributes
  
END
