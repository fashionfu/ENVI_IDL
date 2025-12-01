PRO test_1201Footprint_ENVITask_UI
  COMPILE_OPT idl2
  
  PRINT, ''
  PRINT, '=========================================='
  PRINT, '栅格轮廓提取工具 - 图形界面'
  PRINT, '=========================================='
  PRINT, ''
  
  ; 初始化ENVI
  PRINT, '正在初始化ENVI...'
  e=envi()
  UI = e.UI
  PRINT, 'ENVI初始化完成'
  PRINT, ''
  
  ; 使用ENVI Task的图形界面
  PRINT, '正在加载任务配置文件...'
  taskfile = FILE_DIRNAME(ROUTINE_FILEPATH())+$
    '\test_1201footprint_envitask.task'
  
  IF ~FILE_TEST(taskfile) THEN BEGIN
    PRINT, 'ERROR: 找不到任务配置文件: ', taskfile
    PRINT, '请确保 test_1201footprint_envitask.task 文件存在'
    RETURN
  ENDIF
  
  PRINT, '任务配置文件: ', taskfile
  task = ENVITask(taskfile)
  PRINT, '任务配置加载完成'
  PRINT, ''
  
  ; 显示提示信息
  PRINT, '=========================================='
  PRINT, '请在弹出的对话框中设置参数:'
  PRINT, '  1. 选择输入栅格文件'
  PRINT, '  2. 设置背景值（可选，留空则自动检测）'
  PRINT, '  3. 选择输出矢量文件路径'
  PRINT, '  4. 点击确定开始处理'
  PRINT, '=========================================='
  PRINT, ''
  PRINT, '正在打开参数设置对话框...'
  
  result = UI.SelectTaskParameters(task)
  
  IF result NE 'OK' THEN BEGIN
    PRINT, ''
    PRINT, '用户取消了操作或对话框关闭'
    PRINT, '程序退出'
    RETURN
  ENDIF
  
  PRINT, '参数设置完成'
  PRINT, ''
  PRINT, '=========================================='
  PRINT, '开始执行处理任务...'
  PRINT, '=========================================='
  
  ; 获取开始时间
  startTime = SYSTIME(/SECONDS)
  startTimeStr = SYSTIME()
  PRINT, '开始时间: ', startTimeStr
  PRINT, ''
  PRINT, '处理流程:'
  PRINT, '  [步骤1] 检查栅格背景值（自动）'
  PRINT, '  [步骤2] 确定背景值（自动）'
  PRINT, '  [步骤3] 提取栅格轮廓'
  PRINT, '  [步骤4] 生成矢量文件'
  PRINT, '  [步骤5] 清理资源'
  PRINT, ''
  PRINT, '注意: 处理过程会实时显示在控制台，请查看下方输出了解进度'
  PRINT, '      UI方式与直接运行方式处理速度相同，请耐心等待...'
  PRINT, ''
  PRINT, '------------------------------------------'
  PRINT, '>>> 开始执行任务，详细进度如下:'
  PRINT, '------------------------------------------'
  PRINT, ''
  PRINT, '提示: 如果长时间没有输出，可能是正在打开大文件，请耐心等待...'
  PRINT, '      主程序的输出会实时显示在下方'
  PRINT, ''
  
  ; 执行任务（任务内部会自动检查背景值并提取轮廓）
  PRINT, '>>> 正在调用任务执行程序...'
  PRINT, ''
  
  CATCH, execErr
  task.execute
  IF execErr NE 0 THEN BEGIN
    PRINT, ''
    PRINT, '=========================================='
    PRINT, 'ERROR: 任务执行出错!'
    PRINT, '=========================================='
    PRINT, '错误代码: ', execErr
    PRINT, '错误信息: ', !ERROR_STATE.MSG
    PRINT, '错误位置: ', !ERROR_STATE.SYS_CODE
    CATCH, /CANCEL
    RETURN
  ENDIF
  CATCH, /CANCEL
  
  PRINT, ''
  PRINT, '>>> 任务执行调用完成，等待主程序输出...'
  PRINT, ''
  
  ; 获取结束时间
  endTime = SYSTIME(/SECONDS)
  endTimeStr = SYSTIME()
  elapsedTime = endTime - startTime
  
  PRINT, ''
  PRINT, '------------------------------------------'
  PRINT, '>>> 任务执行完成'
  PRINT, '------------------------------------------'
  PRINT, ''
  PRINT, '=========================================='
  PRINT, '处理完成统计'
  PRINT, '=========================================='
  PRINT, '开始时间: ', startTimeStr
  PRINT, '结束时间: ', endTimeStr
  PRINT, '总耗时: ', STRTRIM(STRING(elapsedTime, FORMAT='(F10.2)'), 2), ' 秒'
  PRINT, '=========================================='
  PRINT, ''
  PRINT, '提示: 请查看上方详细处理信息了解各步骤执行情况'
  PRINT, ''
END
