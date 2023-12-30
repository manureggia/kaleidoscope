declare double @n()

declare double @printval(double)

define double @fact(double %n) {
entry:
  %n1 = alloca double, align 8
  store double %n, ptr %n1, align 8
  %n2 = load double, ptr %n1, align 8
  %lttest = fcmp ult double %n2, 1.000000e+00
  br i1 %lttest, label %trueblock, label %falseblock

trueblock:                                        ; preds = %entry
  br label %mergeblock

falseblock:                                       ; preds = %entry
  %n3 = load double, ptr %n1, align 8
  %n4 = load double, ptr %n1, align 8
  %subres = fsub double %n4, 1.000000e+00
  %calltmp = call double @fact(double %subres)
  %mulres = fmul double %n3, %calltmp
  br label %mergeblock

mergeblock:                                       ; preds = %falseblock, %trueblock
  %0 = phi double [ 1.000000e+00, %trueblock ], [ %mulres, %falseblock ]
  ret double %0
}

define double @main() {
entry:
  %calltmp = call double @n()
  %calltmp1 = call double @fact(double %calltmp)
  %calltmp2 = call double @printval(double %calltmp1)
  ret double %calltmp2
}

