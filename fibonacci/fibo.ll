define double @fibonacci(double %n) {
entry:
  %b = alloca double, align 8
  %a = alloca double, align 8
  %n1 = alloca double, align 8
  store double %n, ptr %n1, align 8
  %n2 = load double, ptr %n1, align 8
  %lttest = fcmp ult double %n2, 2.000000e+00
  br i1 %lttest, label %trueblock, label %falseblock

trueblock:                                        ; preds = %entry
  br label %mergeblock

falseblock:                                       ; preds = %entry
  %n3 = load double, ptr %n1, align 8
  %subres = fsub double %n3, 1.000000e+00
  %calltmp = call double @fibonacci(double %subres)
  store double %calltmp, ptr %a, align 8
  %n4 = load double, ptr %n1, align 8
  %subres5 = fsub double %n4, 2.000000e+00
  %calltmp6 = call double @fibonacci(double %subres5)
  store double %calltmp6, ptr %b, align 8
  %a7 = load double, ptr %a, align 8
  %b8 = load double, ptr %b, align 8
  %addres = fadd double %a7, %b8
  br label %mergeblock

mergeblock:                                       ; preds = %falseblock, %trueblock
  %0 = phi double [ 1.000000e+00, %trueblock ], [ %addres, %falseblock ]
  ret double %0
}

