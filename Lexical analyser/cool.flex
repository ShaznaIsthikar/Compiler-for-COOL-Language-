/* E/17/065 , E/17/312 */

/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

int string_length;
int extra_length;
	
int comment_depth;
	
int is_broken_string = 0;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}
/* declaration of start conditions */
/* can be set to true by writing BEGIN(...) */
%x comment
	
%x string

/*
 * Define names for regular expressions here.
 */

/* giving name DARROW to regular expression => */
DARROW          =>

/* for regular expression matching the string (* */
COMMENT_START	"(*"
	
STRING_START	"\""

NEW		(?i:new)

/* INT_CONST for regular expression matching one or more characters between 0-9 */	
INT_CONST	[0-9]+

/* TRUE for regular expression starts with simple t and other letters may be capital or simple. (since it is case sensitive,to confirm to the rules for other objects,the first letter of true and false must be lowercase)*/	
TRUE		t(?i:rue)

/* TRUE for regular expression starts with simple f and other letters may be capital or simple. (since it is case sensitive)*/	
FALSE		f(?i:alse)
	
ASSIGN		<-
	
NOT		(?i:not)

/* TYPEID for regular expression matching one or more strings of letters or numbers starting with a Uppercase letter */	
TYPEID 		[A-Z][A-Za-z0-9_]*

/* OBJECTID for regular expression matching one or more strings of letters or numbers starting with a Lowercase letter */	
OBJECTID 	[a-z][A-Za-z0-9_]*
	
CLASS		(?i:class)
	
ELSE		(?i:else)
	
IF		(?i:if)
	
FI		(?i:fi)
	
IN		(?i:in)
	
INHERITS	(?i:inherits)
	
LET		(?i:let)
	
LOOP		(?i:loop)
	
POOL		(?i:pool)
	
THEN		(?i:then)
	
WHILE		(?i:while)
	
CASE		(?i:case)

ESAC		(?i:esac)
	
OF		(?i:of)
	
ISVOID		(?i:isvoid)
	
LE		<=

%%

/* RULES - action to perform if the input matches the regular expression or definitions */

 /*
  *  Nested comments
  */

/* INITIAL is active unless you explicitly indicate the beginning of a new state*/

<INITIAL>"*)"	{ cool_yylval.error_msg = "Unmatched *)"; return ERROR; }
	
<INITIAL>{COMMENT_START}	{ BEGIN(comment); comment_depth = 1; }

/* COMMENT_START  only in start condition comment */	
<comment>{COMMENT_START} 	{ comment_depth++; }

/* . only in start condition comment */
<comment>.
<comment>\n			{ curr_lineno++; }
/* *) only in start condition comment (close comment) make the comment depth to zero*/
<comment>"*)" 			{ comment_depth--; if (comment_depth == 0) { BEGIN(INITIAL); } }
<comment><<EOF>>		{ BEGIN(INITIAL); cool_yylval.error_msg = "EOF in comment"; return ERROR; }
	
	
"--".*	{  }
	
	
{STRING_START}		{ BEGIN(string); is_broken_string = 0; string_length = 0; extra_length = 0; memset(&string_buf, 0, MAX_STR_CONST); }
	
<string>"\""		{ BEGIN(INITIAL); string_buf[string_length++] = '\0'; if (string_length > MAX_STR_CONST) { cool_yylval.error_msg = "String constant too long"; return ERROR; } else if (!is_broken_string) { cool_yylval.symbol = stringtable.add_string(string_buf); return STR_CONST; } }
	
<string>"\\\""		{ string_buf[string_length++] = '"'; }
	
<string>"\\n"		{ string_buf[string_length++] = '\n'; }
<string>"\\t"		{ string_buf[string_length++] = '\t'; }
<string>"\\f"		{ string_buf[string_length++] = '\f'; }
<string>"\\b"		{ string_buf[string_length++] = '\b'; }
	
<string>"\\\n"		{ curr_lineno++; string_buf[string_length++] = '\n'; }
	
<string>"\\\\"		{ string_buf[string_length++] = '\\'; }
	
<string>"\\"		{ extra_length++; }

<string>[\0]		{   
				is_broken_string = 1;
	  			cool_yylval.error_msg = "String contains null character";
				return ERROR;
			}
	
<string>\\\0		{   
				is_broken_string = 1;
	  			cool_yylval.error_msg = "String contains escaped null character.";
				return ERROR;
			}
	
	
<string>\n		{   
				curr_lineno++;
				BEGIN(INITIAL);
				if (!is_broken_string) {
	  			cool_yylval.error_msg = "Unterminated string constant";
				return ERROR;
				}
			}
	
<string><<EOF>>		{
	  			cool_yylval.error_msg = "EOF in string constant";
	  			BEGIN(INITIAL); 
				return ERROR;
			}
	
<string>.		{ string_buf[string_length++] = *yytext; }	
	


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }

{LE} {
	return LE;
}

{ASSIGN} {
	return ASSIGN;
}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
  
{NEW}	{
	return NEW;
}
	
{CLASS} {
	return CLASS;
}
	
{ELSE} {
	return ELSE;
}
	
{IF} {
	return IF;
}
	
{FI} {
	return FI;
}
	
{IN} {
	return IN;
}
	
{INHERITS} {
	return INHERITS;
}
	
{LET} {
	return LET;
}
	
{LOOP} {
	return LOOP;
}

{POOL} {
	return POOL;
}
	
{THEN} {
	return THEN;
}
	
{WHILE} {
	return WHILE;
}
	
{CASE} {
	return CASE;
}
	
{ESAC} { 
	return ESAC;
}
	
{OF} {
	return OF;
}
	
{ISVOID} {
	return ISVOID;
}
	


/* records the value of the int_const in the global variable cool_yylval */	
{INT_CONST} {
	/* add the string to the INT table*/
	cool_yylval.symbol = inttable.add_string(yytext);
	return INT_CONST;
}

{TRUE} {
	cool_yylval.boolean = 1;
	return BOOL_CONST;
}
	
{FALSE} {
	cool_yylval.boolean = 0;
	return BOOL_CONST;
}
	
	
{NOT} {
	return NOT;
}
	
{TYPEID} {
	cool_yylval.symbol = stringtable.add_string(yytext);
	return TYPEID;
}
	
{OBJECTID} {
	cool_yylval.symbol = stringtable.add_string(yytext);
	return OBJECTID;
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

	/* according to presedence */

"."	{ return (int)'.'; }
";"	{ return (int)';'; }
","	{ return (int)','; }
")"	{ return (int)')'; }
"("	{ return (int)'('; }
"}"	{ return (int)'}'; }
"{"	{ return (int)'{'; }
"<"	{ return (int)'<'; }
":"	{ return (int)':'; }
"="	{ return (int)'='; }
"+"	{ return (int)'+'; }
"-"	{ return (int)'-'; }
"*"	{ return (int)'*'; }
"/"	{ return (int)'/'; }
"~"	{ return (int)'~'; }
"@"	{ return (int)'@'; }
	
\t|" "|\f|\v|\r
	
\n	{ curr_lineno++; }
	
.	{ cool_yylval.error_msg = strdup(yytext); return ERROR; }

%%
