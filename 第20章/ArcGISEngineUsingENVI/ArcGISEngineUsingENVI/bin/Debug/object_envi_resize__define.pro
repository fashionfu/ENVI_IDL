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
;
;�ز���ִ�й���
;������������Ͳ�������
PRO Object_ENVI_Resize::EXECUTEResize,$
    xfactor, yfactor,method
  COMPILE_OPT idl2, hidden
  
  ;���ļ�
  ENVI_OPEN_FILE, self.INFILENAME, R_FID=fid
  IF (fid EQ -1) THEN RETURN
  ;��ѯ�ļ�������Ϣ
  ENVI_FILE_QUERY, fid, dims=dims, nb=nb
  pos  = LINDGEN(nb)
  ;�ز�������
  ENVI_DOIT, 'resize_doit', $
    fid=fid, pos=pos, dims=dims, $
    interp=1, rfact=1./[XFACTOR,YFACTOR], $
    method = METHOD,$
    out_name=self.OUTFILENAME
    
END
;�������������
PRO Object_ENVI_Resize::CLEANUP
  COMPILE_OPT idl2, hidden  
  ;�ر�ENVI���ο���ģʽ
  ;��Ҫע�⣬COM������øù��ܵ�ʱ�򣬱����������²�����
  ; ��ENVI���˵���File-Preference-Miscellaneous��
  ; ���� Exit IDL on Exit from ENVIΪ'NO'
  ENVI_BATCH_EXIT
END

;ENVI��ʼ������
FUNCTION Object_ENVI_Resize::initEnvi
  CATCH, error_status
  IF Error_status NE 0 THEN BEGIN
    RETURN,-1
    CATCH, /CANCEL
  ENDIF
  ;ENVI���ο���ģʽ��ʼ��
  ENVI,/Restore_Base_Save_Files
  ENVI_BATCH_INIT
  RETURN,1
  
END


;�����ʼ������
;�����������������������ļ�����
;
FUNCTION Object_ENVI_Resize::INIT,$
    inFileName ,outFileName
  COMPILE_OPT idl2
  ;�ļ�������
  self.INFILENAME = inFileName
  self.OUTFILENAME = outFileName
  ;��ʼ��ENVI
  INITFALG = self->INITENVI()
  RETURN, INITFALG
  
END
;�ඨ��
PRO OBJECT_ENVI_RESIZE__DEFINE
  ;�ඨ��ṹ��
  void = {Object_ENVI_Resize, $
    inFileName : '', $
    outFileName : '' $
    }
END