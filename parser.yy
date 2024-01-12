%skeleton "lalr1.cc" /* -*- C++ -*- */
%require "3.2"
%defines

%define api.token.constructor
%define api.location.file none
%define api.value.type variant
%define parse.assert

%code requires {
  # include <string>
  #include <exception>
  class driver;
  class RootAST;
  class ExprAST;
  class NumberExprAST;
  class VariableExprAST;
  class CallExprAST;
  class FunctionAST;
  class SeqAST;
  class PrototypeAST;
  class BlockAST;
  class VarBindingsAST;
  class GlobalVariableAST;
  class AssignmentExprAST;
  class StmtAST; 
  class IfStmtAST;
  class InitAST;
  class ForStmtAST;
}

// The parsing context.
%param { driver& drv }

%locations

%define parse.trace
%define parse.error verbose

%code {
# include "driver.hpp"
}

%define api.token.prefix {TOK_}
%token
  END  0  "end of file"
  SEMICOLON  ";"
  COMMA      ","
  DMINUS     "--"
  MINUS      "-"
  DPLUS      "++"
  PLUS       "+"
  STAR       "*"
  SLASH      "/"
  LPAREN     "("
  RPAREN     ")"
  QMARK      "?"
  COLON      ":"
  LT         "<"
  EQ         "=="
  ASSIGN     "="
  LBRACE     "{"
  RBRACE     "}"
  EXTERN     "extern"
  DEF        "def"
  VAR        "var"
  GLOBAL     "global"
  IF         "if"
  ELSE       "else"
  FOR        "for"
;

%token <std::string> IDENTIFIER "id"
%token <double> NUMBER "number"
%type <ExprAST*> exp
%type <ExprAST*> idexp
%type <ExprAST*> expif 
%type <ExprAST*> condexp
%type <ExprAST*> initexp
%type <std::vector<ExprAST*>> optexp
%type <std::vector<ExprAST*>> explist
%type <RootAST*> program
%type <RootAST*> top
%type <FunctionAST*> definition
%type <PrototypeAST*> external
%type <PrototypeAST*> proto
%type <std::vector<std::string>> idseq
%type <BlockAST*> block
%type <std::vector<VarBindingsAST*>> vardefs;
%type <std::vector<StmtAST*>> stmts;
%type <StmtAST*> stmt;
%type <IfStmtAST*> ifstmt;
%type <VarBindingsAST*> binding;
%type <GlobalVariableAST*> globalvar;
%type <AssignmentExprAST*> assignment;
%type <InitAST*> init;
%type <ForStmtAST*> forstmt;
%%
%start startsymb;

startsymb:
program                 { drv.root = $1; }

program:
  %empty                { $$ = new SeqAST(nullptr,nullptr); }
|  top ";" program      { $$ = new SeqAST($1,$3); };

top:
%empty                  { $$ = nullptr; }
| definition            { $$ = $1; }
| external              { $$ = $1; }
| globalvar             { $$ = $1; };

definition:
  "def" proto block       { $$ = new FunctionAST($2,$3); $2->noemit(); };

external:
  "extern" proto        { $$ = $2; };

proto:
  "id" "(" idseq ")"    { $$ = new PrototypeAST($1,$3);  };

globalvar:
  "global" "id"         {$$ = new GlobalVariableAST($2);};


idseq:
  %empty                { std::vector<std::string> args;
                         $$ = args; }
| "id" idseq            { $2.insert($2.begin(),$1); $$ = $2; };

stmts:
  stmt                  {std::vector<StmtAST*> statemets; statemets.insert(statemets.begin(),$1); $$ = statemets; }
| stmt ";" stmts        {$3.insert($3.begin(),$1); $$ = $3;};

stmt:
  assignment            {$$ = $1;}
| block                 {$$ = $1;}
| ifstmt                {$$ = $1;}
| forstmt               {$$ = $1;}
| exp                   {$$ = $1;};

assignment:
  "id" "=" exp          {$$ = new AssignmentExprAST($1,$3);}
| "++" "id"             {$$ = new AssignmentExprAST($2, new BinaryExprAST('+',new VariableExprAST($2),new NumberExprAST(1)));}
| "id" "++"             {$$ = new AssignmentExprAST($1, new BinaryExprAST('+',new VariableExprAST($1),new NumberExprAST(1)));}
| "--" "id"             {$$ = new AssignmentExprAST($2, new BinaryExprAST('-',new VariableExprAST($2),new NumberExprAST(1)));}
| "id" "--"             {$$ = new AssignmentExprAST($1, new BinaryExprAST('-',new VariableExprAST($1),new NumberExprAST(1)));};


block:
  "{" stmts "}"             { $$ = new BlockAST($2); }
| "{" vardefs ";" stmts "}" { $$ = new BlockAST($2,$4); };

%left ":";
%left "<" "==";
%left "+" "-";
%left "*" "/";

exp:
  exp "+" exp           { $$ = new BinaryExprAST('+',$1,$3); }
| exp "-" exp           { $$ = new BinaryExprAST('-',$1,$3); }
| exp "*" exp           { $$ = new BinaryExprAST('*',$1,$3); }
| exp "/" exp           { $$ = new BinaryExprAST('/',$1,$3); }
| idexp                 { $$ = $1; }
| "(" exp ")"           { $$ = $2; }
| "number"              { $$ = new NumberExprAST($1); }
| expif                 { $$ = $1; };

vardefs:
  binding               { std::vector<VarBindingsAST*> definitions; definitions.push_back($1); $$ = definitions; }
| vardefs ";" binding   { $1.push_back($3); $$ = $1; };

binding:
  "var" "id" initexp    { $$ = new VarBindingsAST($2,$3); };

initexp:
  %empty  {$$ = nullptr;}
| "=" exp {$$ = $2;};

expif:
  condexp "?" exp ":" exp { $$ = new IfExprAST($1,$3,$5);};

ifstmt :
  "if" "(" condexp ")" stmt                   {$$ = new IfStmtAST($3,$5); }
| "if" "(" condexp ")" stmt "else" stmt       {$$ = new IfStmtAST($3,$5,$7); }; 

forstmt :
"for" "(" init ";" condexp ";" assignment ")" stmt {$$ = new ForStmtAST($3,$5,$7,$9);};

init :
  binding {$$ = $1;}
| assignment {$$ = $1;};

condexp:
  exp "<" exp           { $$ = new BinaryExprAST('<',$1,$3); }
| exp "==" exp           { $$ = new BinaryExprAST('=',$1,$3); };

idexp:
  "id"                  { $$ = new VariableExprAST($1); }
| "id" "(" optexp ")"   { $$ = new CallExprAST($1,$3); };

optexp:
  %empty                { std::vector<ExprAST*> args;
			 $$ = args; }
| explist               { $$ = $1; };

explist:
  exp                   { std::vector<ExprAST*> args;
                         args.push_back($1);
			 $$ = args;
                        }
| exp "," explist       { $3.insert($3.begin(), $1); $$ = $3; };
 
%%

void
yy::parser::error (const location_type& l, const std::string& m)
{
  std::cerr << l << ": " << m << '\n';
}
