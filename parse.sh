"use strict";
const fs = require('fs');
const Path = require('path');

const CHAR_SET = 'utf8';


var Lexer = (exports.Lexer = function () {
  this.pos = 0;
  this.buf = null;
  this.buflen = 0;
  this.tokens = [];
//   Set up your parser to maintain a lookahead token as some sort of "global"
// or instance variable. Make sure that when your parser is initialized, it
// primes the lookahead with the rst token read from the lexer.
  this.lookahead = this.tokens[0]

  // Table of single character operators and their kinds, mapping operator to token kind, more can be added
  this.operatorTable = {
    "+": "PLUS",
    "-": "MINUS",
    "*": "MULTIPLY",
    ".": "PERIOD",
    "\\": "BACKSLASH",
    ":": "COLON",
    "%": "PERCENT",
    "|": "PIPE",
    "!": "EXCLAMATION",
    "?": "QUESTION",
    "#": "POUND",
    "&": "AMPERSAND",
    ";": "SEMI",
    ",": "COMMA",
    "(": "L_PAREN",
    ")": "R_PAREN",
    "<": "L_ANG",
    ">": "R_ANG",
    "{": "L_BRACE",
    "}": "R_BRACE",
    "[": "L_BRACKET",
    "]": "R_BRACKET",
    "=": "EQUALS",
  };
});

// From the current buffer, get the next token. A token is a type of object that has the following characteristics:
// - kind: the pattern that this token corresponded to (taken from rules).
// - lexeme: the token's real string value.
// - pos: where the token begins in the current buffer.

// console.log's the tokens array if there are no more tokens in the buffer. If there is a mistake, Error is thrown.
Lexer.prototype.parse = function (buf) {
  this.pos = 0;
  this.buf = buf;
  this.buflen = buf.length;

  while(this.pos < this.buflen){
  this._skipnontokens();
  // This is where the char comes in. Pos is a portion of a genuine token. Find out which is which.
  var c = this.buf.charAt(this.pos);
  
  if (c === "/") {
    var next_c = this.buf.charAt(this.pos + 1);
    if (next_c === "/" || next_c === '*') {
      this._process_comment();
    } else {
      this.tokens.push({ kind: "DIVIDE", lexeme: "/", pos: this.pos++ });
     // return this.tokens
    }
  }else if (c === "#") {
      this._process_comment();
  } else {
    // next thing is to check innthe table of operators for similarity
    var op = this.operatorTable[c];
    if (op !== undefined) {
      this.tokens.push({ kind: op, lexeme: c, pos: this.pos++ });
     // return this.tokens
    } else {
      //if first character is d, process for DEF i.e def
      if (c == "d") {
        const def = "def";
        if (this.buf.substring(this.pos, this.pos + 3) == def) {
          // The reserved word def which is recognized as a token with kind set
          //to DEF.
          var tok = {
            kind: "DEF",
            lexeme: this.buf.substring(this.pos, this.pos + 3),
            pos: this.pos,
          };
          this.pos = this.pos+3;
          this.tokens.push(tok);
        } else {
          this._process_identifier();
        }
      } else if (Lexer._isalpha(c) || c== '_') {
        //The terminal ID must be a sequence of alphanumerics or _ but cannot start with a digit.
        this._process_identifier();
      } else if (Lexer._isInteger(c)) {
    //    • The terminal INT must be a sequence of one-or-more digits.
        this._process_number();
      } else if (c === '"') {
        this._process_quote();
      } else {
        throw Error("Token error at " + this.pos);
      }
    }
  }    
  }

  if (this.pos >= this.buflen) {
      return this.tokens;
  }
};

Lexer._isnewline = function (c) {
  return c === "\r" || c === "\n";
};

Lexer._isInteger = function (c) {
  return c >= "0" && c <= "9";
};

Lexer._isalpha = function (c) {
  return (
    (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c === "_" || c === "$"
  );
};

Lexer._isalphanum = function (c) {
  return (
    (c >= "a" && c <= "z") ||
    (c >= "A" && c <= "Z") ||
    (c >= "0" && c <= "9") ||
    c === "_" ||
    c === "$"
  );
};

Lexer.prototype._process_number = function () {
  var endpos = this.pos + 1;
  while (endpos < this.buflen && Lexer._isInteger(this.buf.charAt(endpos))) {
    endpos++;
  }
  //Integer literals with kind set to INT.
  var tok = {
    kind: "INT",
    lexeme: this.buf.substring(this.pos, endpos),
    pos: this.pos,
  };
  this.pos = endpos;
  this.tokens.push(tok);
  return this.tokens
};

Lexer.prototype._process_comment = function () {
  var endpos = this.pos + 2;
  // Continue until you hit the end of the line.
  var c = this.buf.charAt(this.pos + 2);
  while (endpos < this.buflen && !Lexer._isnewline(this.buf.charAt(endpos))) {
    endpos++;
  }

  var tok = {
    kind: "COMMENT",
    lexeme: this.buf.substring(this.pos, endpos),
    pos: this.pos,
  };
  this.tokens.push(tok);
  this.pos = endpos + 1;

 // return this.tokens
};

Lexer.prototype._process_identifier = function () {
  var endpos = this.pos + 1;
  while (endpos < this.buflen && Lexer._isalphanum(this.buf.charAt(endpos))) {
    endpos++;
  }

  //  Identifiers with kind set to ID.
  var tok = {
    kind: "ID",
    lexeme: this.buf.substring(this.pos, endpos),
    pos: this.pos,
  };
  this.tokens.push(tok);
  this.pos = endpos;

  //return this.tokens

};

Lexer.prototype._process_quote = function () {
  // this.pos is referring to the first quote. Look for the final quote.

  var end_index = this.buf.indexOf('"', this.pos + 1);

  if (end_index === -1) {
    throw Error("Unterminated quote at " + this.pos);
  } else {
    var tok = {
      kind: "QUOTE",
      lexeme: this.buf.substring(this.pos, end_index + 1),
      pos: this.pos,
    };
    this.tokens.push(tok);
    this.pos = end_index + 1;

  //  return this.tokens
  }
};

Lexer.prototype._skipnontokens = function () {
  while (this.pos < this.buflen) {
    var c = this.buf.charAt(this.pos);
    //Additionally, the lexer needs to be set up to ignore whitespace and # to
    //end-of-line comments.
    if (c == " " || c == "\t" || c == "\r" || c == "\n" ||c=='\s') {
      this.pos++;
    } else {
      break;
    }
  }
};

// Write a check() function which returns true i the kind of the lookahead
//token matches the kind provided as its argument.
Lexer.prototype._check = function (kindToBeChecked) {
   if(this.lookahead.kind == kindToBeChecked){
       return true;
   }else{
       return false;
   }
}

// Write a match() function which sets lookahead to the next token from the
// lexer if the lookahead token matches the kind provided as its argument.
// If that is not the case, it should set things up to output a detailed error
// message to standard error and terminate the program.
Lexer.prototype._match = function (kindToBeChecked) {
    for(let i=0;i<this.tokens.length;i++){
        if(kindToBeChecked == this.tokens[i].kind){
         this.lookahead = this.tokens[i+1];
        }else{
            console.log('Error, kind not matched')
process.exit(1)

        }
    }
 }



function main(){
  if(process.argv.length !== 3){
      return errorOnFile()
  }
  const file = process.argv[2];
  const text = fs.readFileSync(file, CHAR_SET);
  var child  = new Lexer()
  child.parse(text)
  child._match('DEF')
// for(const token of child.scan(text)){
//   console.log(token)
// }
}

function errorOnFile(){
// const fileType = Path.basename(process.argv[1])
console.error('No file inputted, please add a file to be scanned')
process.exit(1)
}

main();


