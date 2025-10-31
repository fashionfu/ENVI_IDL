;+
; :Description:
;    ʹ�ô˳������ɾ��file��raster��
;    ����������ENVI���Ѵ򿪣����ֱ�ռ��������޷�ɾ��
;    
;    file�����������ļ�·����ENVIRaster����
;
; :Author: duhj@esrichina.com.cn
;
; :Date: 2018-3-15 15:24:45
;-
PRO File_Delete_Enhanced, file
  COMPILE_OPT idl2

  CASE TYPENAME(file) OF
    'STRING': BEGIN
      ;������ļ�
      FILE_DELETE, file, /quiet, /allow_nonexistent
      IF ~FILE_TEST(file) THEN RETURN
      e=envi()
      tmpraster = e.OpenRaster(file, error=error)
      IF error EQ '' THEN BEGIN
        ;����򿪳ɹ������¼�ļ����رգ�ɾ��
        tmpfiles = [tmpraster.URI, tmpraster.AUXILIARY_URI]
        tmpraster.Close
        FILE_DELETE, tmpfiles, /quiet, /allow_nonexistent
      ENDIF
    END
    'ENVIRASTER': BEGIN
      ;�����ENVIRaster
      tmpfiles = [file.URI, file.AUXILIARY_URI]
      file.Close
      FILE_DELETE, tmpfiles, /quiet, /allow_nonexistent
    END
    ELSE:
  ENDCASE
END