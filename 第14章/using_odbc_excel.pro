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
PRO USING_ODBC_EXCEL
  filename = FILE_DIRNAME(ROUTINE_FILEPATH('Using_ODBC_EXCEL'))+'\SatelliteInformation.xlsx'
  ; �ж��Ƿ�֧�����ݿ⹦��
  IF DB_EXISTS() EQ 0 THEN BEGIN
    msg = DIALOG_MESSAGE('��֧��ODBC!',/Error)
    RETURN
  ENDIF
  ; �½����ݿ����
  oDatabase = OBJ_NEW('IDLdbDatabase')
  ; ��鵱ǰ������������
  sources = oDatabase->GETDATASOURCES()
  index = WHERE(sources.DATASOURCE EQ 'Excel Files',count)
  IF count EQ 0 THEN BEGIN
    msg = DIALOG_MESSAGE('ODBC�޷���ȡExcel Files',/Error)
    OBJ_DESTROY,oDatabase
    RETURN
  ENDIF
  ;�������ݿ�
  IF ~FILE_TEST(filename) THEN BEGIN
    msg = DIALOG_MESSAGE('�Ҳ������ݿ��ļ�!',/Error)
    OBJ_DESTROY,oDatabase
    RETURN
  ENDIF
  ; ���ӵ�����ָ�������ݿ��ļ�
  oDatabase->CONNECT,DATASOURCE='Excel Files;DBQ='+filename
  ;�������ݿ�
  oDatabase->GETPROPERTY,IS_CONNECTED = connectStat
  IF connectStat EQ 0 THEN BEGIN
    msg = DIALOG_MESSAGE('���ݿ����Ӳ��ɹ�...',/Error)
    OBJ_DESTROY,oDatabase
    RETURN
  ENDIF
  
  ;��ȡ���ݿ�������,��ȡ���ݱ�
  tables = oDatabase->GETTABLES()
  nTables = N_ELEMENTS(tables)
  FOR i=0, nTables-1 DO BEGIN
    ; ����ָ����,ע�������Ҫ�ӡ�[]����
    tname = '[' + tables[i].NAME + ']'
    PRINT, 'table name', tname
    
    oRecordset = OBJ_NEW('IDLdbRecordset',oDatabase,table=tname);, SQL=sqlstr)
    ; ��ȡ�ֶ���Ϣ
    oRecordset->GETPROPERTY,field_info = fieldinfo
    NFileds = N_ELEMENTS(fieldinfo)
    ;��ȡ���ݱ��еļ�¼��Ŀ
    IF oRecordset->MOVECURSOR(/first) THEN BEGIN
      FOR j=0, NFileds-1 DO BEGIN
        Value = oRecordset->GETFIELD(j)
        PRINT, 'Talbe: ' + (fieldinfo.TABLE_NAME)[j] + ', ' + $
          'Filed Name: ' + (fieldinfo.FIELD_NAME)[j] + ', ' + $
          'Value: ', Value
      ENDFOR
      WHILE oRecordset->MOVECURSOR(/next) DO BEGIN
        FOR j=0, NFileds-1 DO BEGIN
          Value = oRecordset->GETFIELD(j)
          PRINT, 'Talbe: ' + (fieldinfo.TABLE_NAME)[j] + ', ' + $
            'Filed Name: ' + (fieldinfo.FIELD_NAME)[j] + ', ' + $
            'Value: ', Value
        ENDFOR
      ENDWHILE
    ENDIF ELSE BEGIN ; һ����¼��û��
      msg = DIALOG_MESSAGE('���ݱ��޼�¼',/Infor)
      OBJ_DESTROY, oRecordset
    ENDELSE
    ; �������ݿ����
    OBJ_DESTROY, oRecordset
  ENDFOR
  OBJ_DESTROY,oDatabase
END