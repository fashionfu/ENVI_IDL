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
pro test_drawOrb3
    ;
    oModel = Obj_New('IDLgrModel')
    ;������ɫ����
    angle = findgen(37)*360/36*!Dtor
    inArr = make_array(3,37,/float)
    inArr[0,*] = cos(angle)
    inArr[2,*] = sin(angle)
    Mesh_Obj, 6, Vertex_List, Polygon_List  , $
        inArr, P1 =12 , P2=[0,0,0], $
        P3 = [0,0,1], $
        P4 =0, P5 = 360*!Dtor
    oPoly = Obj_New('IDLgrPolygon', vertex_list, $
        Polygons = polygon_list, $
        color = [96,196,0],style =1) &  oModel->Add,oPoly

    ;������ɫ
    angle = angle/4+135*!Dtor
    inArr = make_array(3,37,/float)
    inArr[0,*] = cos(angle)
    inArr[2,*] = sin(angle)
    Mesh_Obj, 6, Vertex_List, Polygon_List  , $
        inArr, P1 =72 , P2=[0,0,0], $
        P3 = [0,0,1], $
        P4 =0, P5 = 270*!Dtor
    oPoly = Obj_New('IDLgrPolygon', vertex_list, $
        Polygons = polygon_list, $
        color = [196,0,0],style =1) &  oModel->Add,oPoly

    ;������ɫ
    angle = angle-90*!Dtor
    inArr = make_array(3,37,/float)
    inArr[0,*] = cos(angle)
    inArr[2,*] = sin(angle)
    Mesh_Obj, 6, Vertex_List, Polygon_List  , $
        inArr, P1 =72 , P2=[0,0,0], $
        P3 = [1,0,0], $
        P4 =75*!Dtor, P5 = 285*!Dtor
    oPoly = Obj_New('IDLgrPolygon', vertex_list, $
        Polygons = polygon_list, $
        color = [0,0,196],style =1, $
        thick =2) &  oModel->Add,oPoly

    xobjview,oModel;,background = [0,0,0]
end

