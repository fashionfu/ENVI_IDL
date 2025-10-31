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
function modifyConnection, connectivity, numVertices, startIndex

  true = 1
  counter = 1L
  numPoints = n_elements(connectivity)
  newConnectivity = connectivity
  while true eq 1 do begin
    numIndices = newConnectivity[counter-1]
    newConnectivity[counter:counter+numIndices-1] = newConnectivity[counter:counter+numIndices-1] + startIndex
    counter = counter + numIndices + 1
    if counter ge numPoints then true=0
  endwhile
  
  return, newConnectivity
end