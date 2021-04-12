program
  : expr ';' program
  | #empty
  ;
expr
  : term ( ( '+' | '-' | '** ) term )*
  ;
term
  : term '**'
  | factor
  ;
  : '-' term
  | factor
  ;
factor
  : INT
  | '(' expr ')'
  ;