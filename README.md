# kaleidoscope

Progetto per l'ampliazione della grammatica di base di kaleidoscope-1.0.
Questo progetto si divide in 4 punti, con corrispettive grammatiche da implementare:

### grammatica di primo livello

Per questa grammatica è necessario implementare l'assegnamento, l'inizializzazioni di variabili locali e globali.
Essendo l'assegnamento e il binding due operazioni logicamente simili viene naturale pensare di raggrupparle sotto una unica classe "virtuale" che racchiuda i principali metodi per queste due classi che andremo a implementare: `VarBindingAST` e `AssignmentExprAST`. Entrambe le classi derivano da una classe madre chiamata `InitAST` implementata nel seguente modo:
```c++
class InitAST : public StmtAST{
  private:
    std::string Name;
  public:
    
    virtual std::string& getName();
    virtual initType getType();
};
```
È necessario l'implementazione di un metodo chiamato `getType()`, utile per distinguere all'interno del codice se si sta eseguendo una assegnamento o un binding, in quanto ritornano al programma due tipi di dato differenti.
`initType` è semplicemente un enum fatto nel seguente modo:
```c++
enum initType {
  ASSIGNMENT,
  BINDING,
  INIT
};
```
#### Binding

Il binding è gestito dalla classe `VarBindingAST`, figlia della classe `InitAST` e implementata nel seguente modo:

```c++
VarBindingsAST::VarBindingsAST(std::string Name, ExprAST* Val) : Name(Name), Val(Val) {};
std::string& VarBindingsAST::getName(){ return Name; };
initType VarBindingsAST::getType() {return BINDING;};

AllocaInst* VarBindingsAST::codegen(driver& drv) {
  Function *fun = builder->GetInsertBlock()->getParent();
  Value* boundval;
  if (Val)
    boundval = Val->codegen(drv);
  else{
    NumberExprAST* defaultVal = new NumberExprAST(0.0);
    boundval = defaultVal->codegen(drv);
  }
  AllocaInst* Alloca = CreateEntryBlockAlloca(fun,Name);
  builder->CreateStore(boundval,Alloca);
  return Alloca;
};
```
#### Assegnamento

L'assegnamento prevede il fatto che una variabile, quindi un nome nel driver, esista già, quindi di fatto che sia stato eseguito un bindign "in un certo punto". La classe implementata è sempre derivante da `InitAST`, ma ovviamente differisce nella logica di generazione del codice

```c++
AssignmentExprAST::AssignmentExprAST(std::string Name, ExprAST* Val, ExprAST* Pos) : Name(Name), Val(Val), Pos(Pos) {};
std::string& AssignmentExprAST::getName(){ return Name; };
initType AssignmentExprAST::getType() {return ASSIGNMENT;};
Value* AssignmentExprAST::codegen(driver& drv) {
  AllocaInst *Variable = drv.NamedValues[Name];
  Value* boundval = Val->codegen(drv);
  if(!boundval) return nullptr;
  if (!Variable){
    GlobalVariable* globVar = module->getNamedGlobal(Name);
    if(!globVar) return nullptr;
    if(Pos){
      Value* doubleIndex = Pos->codegen(drv);
      if(!doubleIndex) return nullptr;
      Value* floatIndex = builder->CreateFPTrunc(doubleIndex, Type::getFloatTy(*context));
      Value* intIndex = builder->CreateFPToSI(floatIndex, Type::getInt32Ty(*context));
      Value* cell = builder->CreateInBoundsGEP(globVar->getValueType(),globVar,intIndex);
      builder->CreateStore(boundval,cell);
    }
    else
      builder->CreateStore(boundval,globVar);
    return boundval;
  }
  if(Pos){
    Value* doubleIndex = Pos->codegen(drv);
    if(!doubleIndex) return nullptr;
    Value* floatIndex = builder->CreateFPTrunc(doubleIndex, Type::getFloatTy(*context));
    Value* intIndex = builder->CreateFPToSI(floatIndex, Type::getInt32Ty(*context));    
    Value* cell = builder->CreateInBoundsGEP(Variable->getAllocatedType(),Variable,intIndex);
    builder->CreateStore(boundval,cell);
  }
  else
    builder->CreateStore(boundval,Variable);
  return boundval;
};
```
Qui è già presente della logica per l'individuazione dell'array, che vengono poi spiegate dopo

#### Variabili globali

Le variabili globali sono implementate in modo differente dalle variabili locali, si utilizza una classe `GlobalVariable`, che gestisce praticamente tutto out-of-the-box. bisogna stare attenti allo scope: nelle istruzioni che comprendono il retrive di valori di variabili, andranno prima controllati gli scope locali e infine quello globale.
la classe, che deriva `RootAST` è quindi implementata nel seguente modo:

```c++
GlobalVariableAST::GlobalVariableAST(std::string Name, double Size, bool isArray) : Name(Name), Size(Size), isArray(isArray) {}
std::string& GlobalVariableAST::getName(){ return Name; };
Value* GlobalVariableAST::codegen(driver &drv){
  GlobalVariable *globVar;
  if (isArray){
    if(Size < 1) return nullptr;
    ArrayType *AT = ArrayType::get(Type::getDoubleTy(*context),Size);
    globVar = new GlobalVariable(*module, AT, false, GlobalValue::CommonLinkage,  ConstantFP::getNullValue(AT), Name);    
  }
  else{
    globVar = new GlobalVariable(*module, Type::getDoubleTy(*context), false, GlobalValue::CommonLinkage,  ConstantFP::getNullValue(Type::getDoubleTy(*context)), Name);    
  }
  globVar->print(errs());
  fprintf(stderr, "\n");
  return globVar;
}
```

#### Variable expression

Come detto sopra, l'implementazione di variabili su differenti scope, impone che quando si va a riprendere il valore di un determinato nome si cotrolli in maniera gerarchica: prima il nome locale, poi eventualmente quello globale.
Questo va implementato nel nostro codice tramite la seguente modifica alla classe già esistente

```c++
VariableExprAST::VariableExprAST(const std::string &Name, ExprAST* Exp , bool isArray): 
  Name(Name), Exp(Exp), isArray(isArray) {};

lexval VariableExprAST::getLexVal() const {
  lexval lval = Name;
  return lval;
};

Value *VariableExprAST::codegen(driver& drv) {
  AllocaInst *A = drv.NamedValues[Name];
  if (!A){
    GlobalVariable* globVar = module->getNamedGlobal(Name);
    if (!globVar)
      return LogErrorV("Variabile non definita: "+Name);
    if(isArray){
      Value* Val = Exp->codegen(drv);
      if(!Val) return nullptr;
      Value* floatIndex = builder->CreateFPTrunc(Val, Type::getFloatTy(*context));
      Value* intIndex = builder->CreateFPToSI(floatIndex, Type::getInt32Ty(*context));
      Value* cell = builder->CreateInBoundsGEP(globVar->getValueType(),globVar,intIndex);
      return builder->CreateLoad(Type::getDoubleTy(*context), cell, Name.c_str());
    }
    return builder->CreateLoad(globVar->getValueType(), globVar, Name.c_str());
  }
  if(isArray){
      Value* Val = Exp->codegen(drv);
      if(!Val) return nullptr;
      Value* floatIndex = builder->CreateFPTrunc(Val, Type::getFloatTy(*context));
      Value* intIndex = builder->CreateFPToSI(floatIndex, Type::getInt32Ty(*context));
      Value* cell = builder->CreateInBoundsGEP(A->getAllocatedType(),A,intIndex);
      return builder->CreateLoad(Type::getDoubleTy(*context), cell, Name.c_str());
    }
  return builder->CreateLoad(A->getAllocatedType(), A, Name.c_str());
}
```
> anche qui è già implementata la logica per quanto riguarda gli array che vedremo dopo

### grammatica di secondo livello

Per questa grammatica è necessario implementare il concetto di `statment` e ripensare la logica dei blocchi visti fino ad ora. Si implementaranno poi dei costrutti di control flow come `if` e `for`.

#### Gli statement

Per quanto rigurada l'implementazione di logiche di control-flow è necessario prima definire (logicamente) il concetto di statment. Qui rappresentato da una classe `StmtAST` che eredita direttamente da `RootAST`, senza però implementare nulla di nuovo. Questa nuova classe sarà poi padre di: if, for, blocco e delle espressioni.

#### If

Lo statment if, rappresentato dalla classe `IfStmtAST`, implementa la logica già vista prima nelle IF expression, in maniera più estesa. 
L'implementazione è la seguente:

```c++
IfStmtAST::IfStmtAST(ExprAST* cond, StmtAST* trueblock, StmtAST* falseblock):
  cond(cond), trueblock(trueblock), falseblock(falseblock) {};

IfStmtAST::IfStmtAST(ExprAST* cond, StmtAST* trueblock):
  cond(cond), trueblock(trueblock) {};

Value* IfStmtAST::codegen(driver& drv){
  Value* CondV = cond->codegen(drv);
  if (!CondV) return nullptr;

  Function *fun = builder->GetInsertBlock()->getParent();
  BasicBlock *TrueBB = BasicBlock::Create(*context, "trueblock",fun);
  BasicBlock *FalseBB = BasicBlock::Create(*context, "falseblock");
  BasicBlock *MergeBB = BasicBlock::Create(*context, "mergeblock");
  
  
  builder->CreateCondBr(CondV, TrueBB, FalseBB);
  

  builder->SetInsertPoint(TrueBB);
  Value* trueV = trueblock->codegen(drv);
  if(!trueV) return nullptr;

  TrueBB = builder->GetInsertBlock();
  builder->CreateBr(MergeBB);

  builder->SetInsertPoint(FalseBB);
  Value* falseV;
  fun->insert(fun->end(), FalseBB);
  builder->SetInsertPoint(FalseBB);
  if(falseblock){
    falseV = falseblock->codegen(drv);
    if(!falseV) return nullptr;
    FalseBB = builder->GetInsertBlock();
  }
  builder->CreateBr(MergeBB);

  fun->insert(fun->end(),MergeBB);
  builder->SetInsertPoint(MergeBB);

  PHINode *P = builder->CreatePHI(Type::getDoubleTy(*context),2);
  P-> addIncoming(ConstantFP::getNullValue(Type::getDoubleTy(*context)), TrueBB);
  P-> addIncoming(ConstantFP::getNullValue(Type::getDoubleTy(*context)), FalseBB);
  return P;
  
  
};
```
L'implementazione, per semplicità è stata quella di creare in tutti i casi un blocco false, anche nell'eventualità della non presenza del blocco else. Questo escamotage permette di avere sempre un bilanciamento dei nodi PHI di ritorno anche nel caso di if innestati.
Questi ultimi sono anche autori di conflitti shif reduce, risolti nella seguente maniera:

```
%right "then" "else" ; 

ifstmt :
  "if" "(" condexp ")" stmt                   {$$ = new IfStmtAST($3,$5); } %prec "then"
| "if" "(" condexp ")" stmt "else" stmt       {$$ = new IfStmtAST($3,$5,$7); }; 
```

In questa maniera scegliamo di dare un nome (`then`) al ramo true, e specifichiamo che la parola chiave "else" ha stessa priorità del blocco "then", ma in caso di conflitto shift-reduce, vince lo shift, quindi in caso di mancanza di parentesi, l'else vine associato al primo if che lo precede, proprio come accade in c++.

#### for

L'implementazione del for è stata fatta nella maniera classica, una classe che eredita dagli statment, chiamata `ForStmtAST`. Il flow nautrale del for è stato rispettato:
- salvataggio di variabili in caso di conflitto di scope durante l'inizializzazione della variabile "iteratore" 
- valutazione della condizione
- esecuzione del body
- esecuzione dell'espressione di "incremento"
- jump incondizionato alla condizione

Quanto detto è implementato nella classe nel seguente modo

```c++
ForStmtAST::ForStmtAST(InitAST* init, ExprAST* cond, AssignmentExprAST* step, StmtAST* body):
init(init), cond(cond), step(step), body(body) {};
Value* ForStmtAST::codegen(driver& drv) {
  
  Function *fun = builder->GetInsertBlock()->getParent();
  BasicBlock *InitBB = BasicBlock::Create(*context, "init",fun);
  builder->CreateBr(InitBB);
  //inizializzazione
  BasicBlock *CondBB = BasicBlock::Create(*context, "cond",fun);
  BasicBlock *LoopBB = BasicBlock::Create(*context, "loop",fun);
  BasicBlock *EndLoop = BasicBlock::Create(*context, "endloop",fun);
  
  builder->SetInsertPoint(InitBB);
  
  std::string varName = init->getName();
  AllocaInst* oldVar;
  Value* initVal = init->codegen(drv);;
  if (!initVal) return nullptr;
  //controllo se sono assigment -> il getType mi restituisce ASSIGMENT o BINDING
  if (init->getType() == BINDING){
    oldVar = drv.NamedValues[varName];
    drv.NamedValues[varName] = (AllocaInst*) initVal;  
  }
  builder->CreateBr(CondBB);
  //valutazione condizione
  builder->SetInsertPoint(CondBB);
  Value *condVal = cond->codegen(drv);
  if(!condVal) return nullptr;
  builder->CreateCondBr(condVal, LoopBB, EndLoop);
  //body
  builder->SetInsertPoint(LoopBB);
  Value *bodyVal = body->codegen(drv);
  if(!bodyVal) return nullptr;
  //step
  Value* stepVal = step->codegen(drv);
  if(!stepVal) return nullptr;

  //br incondizionato all'inizio del loop
  builder->CreateBr(CondBB);
  //End loop
  builder->SetInsertPoint(EndLoop);
  PHINode *P = builder->CreatePHI(Type::getDoubleTy(*context),1);
  P->addIncoming(ConstantFP::getNullValue(Type::getDoubleTy(*context)),CondBB);

  if(init->getType() == BINDING){
    drv.NamedValues[varName] = oldVar; //rimetto i valori originali della symb
  }
  return P;
};
```

### grammatica di terzo livello

Per questa grammatica è necessario implementare il concetto di espressioni relazionari, quindi dell'aggiuta di condizioni booleane come `and, or, not` per tutte quelle espressioni definite come condizionali.

Questa grammatica è relativamente semplice da implementare, basta modificare la già prensete classe `BinaryExprAST` nel seguente modo. Per semplicità, anche se non del tutto corretto logicamente, il not (operatore unario) è stato implementato lo stesso in questa classe.

```c++
BinaryExprAST::BinaryExprAST(char Op, ExprAST* LHS, ExprAST* RHS):
  Op(Op), LHS(LHS), RHS(RHS) {};
Value *BinaryExprAST::codegen(driver& drv) {
  if (Op == 'n'){
    Value *R = RHS->codegen(drv);
    if(!R) return nullptr;
    return builder->CreateNot(R,"notres");
  }
  Value *L = LHS->codegen(drv);
  Value *R = RHS->codegen(drv);
  if (!L || !R) 
     return nullptr;
  switch (Op) {
  case '+':
    return builder->CreateFAdd(L,R,"addres");
  case '-':
    return builder->CreateFSub(L,R,"subres");
  case '*':
    return builder->CreateFMul(L,R,"mulres");
  case '/':
    return builder->CreateFDiv(L,R,"addres");
  case '<':
    return builder->CreateFCmpULT(L,R,"lttest");
  case '>':
    return builder->CreateFCmpUGT(L,R,"gttest");
  case '=':
    return builder->CreateFCmpUEQ(L,R,"eqtest");
  case 'a':
    return builder->CreateLogicalAnd(L,R,"andres");
  case 'o':
    return builder->CreateLogicalOr(L,R,"orres");
  default:  
    std::cout << Op << std::endl;
    return LogErrorV("Operatore binario non supportato");
  }
};
```
Come si può vedere il primo controllo fatto è quello se l'operazione è o meno un not, in quel caso non si considera nemmeno cosa compare a sinistra, il not riguarderà solo ciò che viene a destra.

### grammatica di quarto livello

Per questa grammatica è necessario estendere il concetto di variabile a degli array statici, definiti sia globalmente sia localmente.

Per fare questo si è deciso di procedere in due maniere implementative differenti. Per quanto riguarda la creazione, quindi il binding, attraverso una classe dedicata, ereditante anche essa da `InitAST`, mentre per l'assegnamento si è modificato la classe `AssigmentExprAST`. Il codice dell'assegnamento è identico a quello già mostrato.

#### Binding di un array

La logica è quella di un Binding normale, bisogna tenere conto però che si sta lavorando con un altro tipo di dato. Questo tipo di dato è `ArrayType`. una volta creato questo tipo di dato lo si passa alla funzione che crea l'allocamento della memoria. Qui si può decidere se inzializzarlo con dei valori predefiniti o lasciarlo vuoto.
La classe è implementata nel seguente modo:

```c++
ArrayBindingAST::ArrayBindingAST(std::string Name, double Size, std::vector<ExprAST*> Val) :
  Name(Name), Size(Size), Val(std::move(Val)) {};

std::string& ArrayBindingAST::getName(){ return Name; };
initType ArrayBindingAST::getType() {return BINDING;};

AllocaInst* ArrayBindingAST::codegen(driver& drv) {
  Function *fun = builder->GetInsertBlock()->getParent();
  int intSize = Size;
  ArrayType *AT = ArrayType::get(Type::getDoubleTy(*context),intSize);
  AllocaInst *Alloca = CreateEntryBlockAlloca(fun,Name,AT);
  for(int i = 0; i<Size; i++){
    Value* Index = builder->CreateInBoundsGEP(AT,Alloca,ConstantInt::get(*context,APInt(32,i,true)));
    if(Val.size() != 0){
      Value* actVal = Val[i]->codegen(drv);
      if(!actVal) return nullptr;
      builder->CreateStore(actVal, Index);
    }
  }
  return Alloca;
}
```

# Far partire il progetto

Per far compilare il progetto e creare il file `kcomp` con cui compilare i file di kaleidoscope si utilizza il comando

```shell
make
make all
```

Per far copilare un programma, linkarlo con il suo corrispettivo _caller_,  si utilizza il make-file all'interno della cartella `test_progetto` attraverso il comando:
```
make <nome_file>
``` 
oppure per compilarli tutti:
```
make 
```

> assicurarsi di avere il `kcomp` all'interno della cartella padre e non dentro a `test_progetto`
