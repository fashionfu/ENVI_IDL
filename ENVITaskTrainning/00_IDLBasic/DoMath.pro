;函数
FUNCTION DoMath, a, b
  result = a+b
  RETURN, result
END

;调用示例
a=10
b=20
c = DoMath(a,b)
print, c
END