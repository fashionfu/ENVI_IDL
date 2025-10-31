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
;ENVI���Զ���Ӳ˵�
PRO ENVI_READ_AWX_DEFINE_BUTTONS,buttonInfo
  ENVI_DEFINE_MENU_BUTTON, buttonInfo,  VALUE = 'AWX', $
    uValue = '', $
    event_pro ='ENVI_READ_AWX', $
    REF_VALUE = 'Generic Formats', $
    POSITION = 1, REF_INDEX = 0
END
;AWX�ļ���������
PRO ENVI_READ_AWX,event
  compile_opt strictarr
  ;��ȡENVIĬ�����ò���
  cfg = envi_get_configuration_values()
  ;Ĭ�����ݴ�Ŀ¼
  inPath = cfg.DEFAULT_DATA_DIRECTORY
  ;�Ի���ѡ���ļ�
  file = DIALOG_PICKFILE(path = inPath, $
    filter ='*.awx',title ='ѡ��AWX�ļ�')
  ;�ж��ļ��Ƿ����
  IF FILE_TEST(file) NE 1 THEN RETURN
  ;���ļ�
  OPENR, file_lun, file ,/Get_Lun
  ;��λ����Ϣ����
  POINT_LUN,file_lun,20
  HeadLine =INDGEN(3)
  READU,file_lun,HeadLine
  ;��λ����Ϣ����
  POINT_LUN,file_lun,58
  BeginDate=INDGEN(5) ;����Ϊ������ʱ��
  EndDate =INDGEN(5)	;����Ϊ������ʱ��
  ;��ȡ
  READU,file_lun,BeginDate
  READU,file_lun,EndDate
  descriptionStr = '��ʼʱ�䣺'+STRJOIN(StrTrim(BeginDate,2),'-')+$
    '����ʱ�䣺'+STRJOIN(StrTrim(EndDate,2),'-')
  ;��������
  data = BYTARR(HeadLine[2],(HeadLine[0]))
  ;��λ�����ݲ���
  POINT_LUN,file_lun,HeadLine[0]*HeadLine[1]
  READU,file_lun,data
  ;�ر��ļ�lun
  FREE_LUN,file_lun
  ;����ENVI����
  ENVI_SETUP_HEAD, fname=file, $
    ns=headLine[2], nl=HeadLine[0], nb=1, $
    DESCRIP=descriptionStr, $
    interleave=0, data_type=1, $
    offset=HeadLine[0]*HeadLine[1], /write, /open
END