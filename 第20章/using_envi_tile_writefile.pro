;+
;         ��IDL������ơ�
; --���ݿ��ٿ��ӻ���ENVI���ο��������̣�
;
; ʾ��Դ����
;
; ����: ������
;
; ��ϵ��ʽ��sdlcdyq@sina.com
;
;-

PRO USING_ENVI_TILE_WRITEFILE
  COMPILE_OPT IDL2
  
  ;�ָ�ENVI��sav�ļ�
  ENVI, /RESTORE_BASE_SAVE_FILES
  ;��ʼ��ENVI����������־�ļ�
  ENVI_BATCH_INIT
  ;ENVI�������ļ�
  ENVI_OPEN_FILE, fname, r_fid=fid
  ;ѡ������ļ���
  out_name = DIALOG_PICKFILE(title='ѡ������ļ���', $
    /Write)
  IF out_name EQ '' THEN   RETURN
  
  ;�������ļ�����ȡ�ļ�ID
  ENVI_OPEN_FILE,fname,R_fid = fid
  
  IF (fid EQ -1) THEN RETURN
  ;�����ļ�ID����ѯ�ļ�������Ϣ
  ENVI_FILE_QUERY, fid, $
    data_type=data_type, $
    ns=ns, $
    nl=nl, $
    nb=nb, $
    dims=dims
  pos = lindgen(nb)
  ;���ļ�������ȡ�ļ��豸��unit
  OPENW, unit, out_name, /get_lun
  ;ENVI�ֿ��ʼ������
  tile_id = ENVI_INIT_TILE(fid, pos, interleave=0, $
    num_tiles=num_tiles, xs=dims[1], xe=dims[2], $
    ys=dims[3], ye=dims[4])
  ;���ζ�ȡ���Ӧ����
  FOR i=0L, num_tiles-1 DO BEGIN
    ;��ȡ������
    data = ENVI_GET_TILE(tile_id, i, band_index=band_index)
    ;�鿴��ǰ�������벨������
    PRINT, i, band_index
    ;�������Ŀ����ݴ洢���ļ���
    WRITEU, unit, data
  ENDFOR
  ;�ر��ļ��豸��
  FREE_LUN, unit
  
  ;��������ļ���hdrͷ��Ϣ����
  ENVI_SETUP_HEAD, $
    fname=out_name, $     ;����ļ���
    ns=ns, $              ;��������
    nl=nl, $              ;��������
    nb=nb, $              ;������
    data_type=data_type, $;��������
    offset=0, $           ;ƫ����
    interleave=0, $      ;�洢��ʽ
    descrip='save envi standard file',$;�ļ�������Ϣ
    /write                ;д�����ļ�
    
  ;�رտ�ID
  ENVI_TILE_DONE, tile_id
  ;ENVI���ο���ģʽ�ر�
  ENVI_BATCH_EXIT
  
  
END

