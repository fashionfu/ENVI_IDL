;+
; :Description:
;    使用此程序可以删除file、raster等
;    避免数据在ENVI中已打开，出现被占用情况而无法删除
;    
;    file参数可以是文件路径、ENVIRaster对象。
;
; :Author: duhj@esrichina.com.cn
;
; :Date: 2018-3-15 15:24:45
;-
PRO File_Delete_Enhanced, file
  COMPILE_OPT idl2

  CASE TYPENAME(file) OF
    'STRING': BEGIN
      ;如果是文件
      FILE_DELETE, file, /quiet, /allow_nonexistent
      IF ~FILE_TEST(file) THEN RETURN
      e=envi()
      tmpraster = e.OpenRaster(file, error=error)
      IF error EQ '' THEN BEGIN
        ;如果打开成功，则记录文件，关闭，删除
        tmpfiles = [tmpraster.URI, tmpraster.AUXILIARY_URI]
        tmpraster.Close
        FILE_DELETE, tmpfiles, /quiet, /allow_nonexistent
      ENDIF
    END
    'ENVIRASTER': BEGIN
      ;如果是ENVIRaster
      tmpfiles = [file.URI, file.AUXILIARY_URI]
      file.Close
      FILE_DELETE, tmpfiles, /quiet, /allow_nonexistent
    END
    ELSE:
  ENDCASE
END