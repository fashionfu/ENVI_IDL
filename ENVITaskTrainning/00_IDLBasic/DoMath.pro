;����
FUNCTION DoMath, a, b
  result = a+b
  RETURN, result
END

;����ʾ��
a=10
b=20
c = DoMath(a,b)
print, c
END