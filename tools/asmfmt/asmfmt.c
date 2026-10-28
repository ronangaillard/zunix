/*
 * asmfmt: formatter for Z80 assembly in the sdasz80 (ASxxxx) syntax.
 *
 *   asmfmt                     stdin -> stdout (what VS Code calls on save)
 *   asmfmt file...             rewrites the files in place
 *   asmfmt --check file...     lists the files that are not formatted, exit 1 if any
 *
 * Layout, tab = 8 columns:
 *
 *   label:                         column 0
 *   1$:     halt                   a label shorter than a tab keeps its instruction
 *   NAME = value                   assignments (=, ==, =:) at column 0
 *           ld      a, #0x18       one tab, mnemonic, one tab, ", " between operands
 *           ret                    ; trailing comments start at column 40
 *   ; text                         whole-line comments are left as they are
 *
 * Case is never changed. Operands are kept as written except for the space after the
 * commas that separate them; strings and character constants are never touched.
 */

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAB         8
#define COMMENT_COL 40

/* ---- growable output buffer ------------------------------------------------------------ */

typedef struct {
	char *p;
	size_t len, cap;
} buf;

static void put(buf *b, const char *s, size_t n)
{
	if (b->len + n + 1 > b->cap) {
		b->cap = (b->len + n + 1) * 2;
		b->p = realloc(b->p, b->cap);
		if (!b->p) {
			perror("asmfmt");
			exit(2);
		}
	}
	memcpy(b->p + b->len, s, n);
	b->len += n;
	b->p[b->len] = 0;
}

static void puts_(buf *b, const char *s) { put(b, s, strlen(s)); }
static void putc_(buf *b, char c) { put(b, &c, 1); }

/* Screen column reached by the current (last) line of b. */
static int column(const buf *b)
{
	size_t start = b->len;
	int col = 0;

	while (start > 0 && b->p[start - 1] != '\n')
		start--;
	for (size_t i = start; i < b->len; i++)
		col = (b->p[i] == '\t') ? (col / TAB + 1) * TAB : col + 1;
	return col;
}

/* Pads with tabs up to COMMENT_COL (at least one tab), then writes the comment. */
static void put_comment(buf *b, const char *s, size_t n)
{
	int col = column(b);

	do {
		putc_(b, '\t');
		col = (col / TAB + 1) * TAB;
	} while (col < COMMENT_COL);
	put(b, s, n);
}

/* ---- scanning ---------------------------------------------------------------------------- */

/* Characters of an ASxxxx symbol: letters, digits, '_', '.', '$' (1$ local labels). */
static int issym(int c) { return isalnum(c) || c == '_' || c == '.' || c == '$'; }

static int isblank_(int c) { return c == ' ' || c == '\t'; }

static size_t skip_blanks(const char *s, size_t i, size_t n)
{
	while (i < n && isblank_(s[i]))
		i++;
	return i;
}

/* .ascii and friends take a string between any delimiter: .ascii "text" or .ascii /text/ */
static int is_string_directive(const char *s, size_t n)
{
	static const char *const names[] = {".ascii", ".asciz", ".ascis", ".str", ".strz", ".strs"};

	for (size_t i = 0; i < sizeof names / sizeof *names; i++)
		if (strlen(names[i]) == n && strncasecmp(s, names[i], n) == 0)
			return 1;
	return 0;
}

/*
 * Length of the literal starting at s[i] (1 if it is not one), so that its characters are
 * never mistaken for a ';' or a ','. In ASxxxx 'c is one character and "cc two, with no
 * closing quote. The quote of af' (ex af, af') is not a literal.
 */
static size_t literal_len(const char *s, size_t i, size_t n)
{
	size_t len = 1;

	if (s[i] == '\'') {
		if (i >= 2 && tolower((unsigned char)s[i - 2]) == 'a' &&
		    tolower((unsigned char)s[i - 1]) == 'f' && (i < 3 || !issym(s[i - 3])))
			return 1;
		len = 2;
	} else if (s[i] == '"') {
		len = 3;
	}
	return (i + len <= n) ? len : n - i;
}

/*
 * Index of the ';' that starts the comment in s[i..n), or n. For a string directive the
 * first non-blank character is the delimiter and everything up to the next one is text.
 */
static size_t find_comment(const char *s, size_t i, size_t n, int string_directive)
{
	if (string_directive) {
		i = skip_blanks(s, i, n);
		if (i < n && s[i] != ';') {
			char delim = s[i++];
			while (i < n && s[i] != delim)
				i++;
			if (i < n)
				i++;
		}
	}
	while (i < n && s[i] != ';')
		i += literal_len(s, i, n);
	return i;
}

static size_t rtrim(const char *s, size_t i, size_t n)
{
	while (n > i && isblank_(s[n - 1]))
		n--;
	return n;
}

/* Copies operands, writing ", " after each comma that separates two of them. */
static void put_operands(buf *b, const char *s, size_t n)
{
	int depth = 0;

	for (size_t i = 0; i < n;) {
		char c = s[i];

		if (c == '(' || c == '[')
			depth++;
		else if ((c == ')' || c == ']') && depth > 0)
			depth--;

		if (c == ',' && depth == 0) {
			while (b->len > 0 && isblank_(b->p[b->len - 1]))
				b->len--;
			puts_(b, ", ");
			i = skip_blanks(s, i + 1, n);
			continue;
		}
		size_t len = literal_len(s, i, n);
		put(b, s + i, len);
		i += len;
	}
}

/* ---- one line ---------------------------------------------------------------------------- */

static void format_line(buf *b, const char *s, size_t n)
{
	size_t i, j, c;

	n = rtrim(s, 0, n);
	i = skip_blanks(s, 0, n);

	if (i == n)
		goto end;
	if (s[i] == ';') { /* whole-line comment: as written */
		put(b, s, n);
		goto end;
	}

	/* Labels: "name:" or "name::", possibly several. All but the last get their own line. */
	int label = 0;
	for (;;) {
		j = i;
		while (j < n && issym(s[j]))
			j++;
		if (j == i || j >= n || s[j] != ':')
			break;
		j += (j + 1 < n && s[j + 1] == ':') ? 2 : 1;
		if (label)
			putc_(b, '\n');
		put(b, s + i, j - i);
		label = 1;
		i = skip_blanks(s, j, n);
	}

	if (i == n)
		goto end;
	if (s[i] == ';') { /* "label: ; comment" */
		put_comment(b, s + i, n - i);
		goto end;
	}

	/* Assignment: NAME = value, NAME == value (global), NAME =: value (local) */
	j = i;
	while (j < n && issym(s[j]))
		j++;
	size_t k = skip_blanks(s, j, n);
	if (j > i && k < n && s[k] == '=') {
		size_t op = k++;
		if (k < n && (s[k] == '=' || s[k] == ':'))
			k++;
		if (label)
			putc_(b, '\n');
		put(b, s + i, j - i);
		putc_(b, ' ');
		put(b, s + op, k - op);
		k = skip_blanks(s, k, n);
		c = find_comment(s, k, n, 0);
		size_t end = rtrim(s, k, c);
		if (end > k) {
			putc_(b, ' ');
			put(b, s + k, end - k);
		}
		if (c < n)
			put_comment(b, s + c, n - c);
		goto end;
	}

	/* Instruction or directive: mnemonic, then operands. */
	if (label && column(b) >= TAB)
		putc_(b, '\n');
	putc_(b, '\t');
	j = i;
	while (j < n && !isblank_(s[j]) && s[j] != ';')
		j++;
	put(b, s + i, j - i);

	int string_directive = is_string_directive(s + i, j - i);
	k = skip_blanks(s, j, n);
	c = find_comment(s, k, n, string_directive);
	size_t end = rtrim(s, k, c);
	if (end > k) {
		putc_(b, '\t');
		if (string_directive)
			put(b, s + k, end - k);
		else
			put_operands(b, s + k, end - k);
	}
	if (c < n)
		put_comment(b, s + c, n - c);
end:
	putc_(b, '\n');
}

/* Formats a whole file. Blank lines are kept, except at the end: exactly one '\n' there. */
static buf format(const char *s, size_t n)
{
	buf b = {0};

	for (size_t i = 0; i < n;) {
		size_t e = i;
		while (e < n && s[e] != '\n')
			e++;
		size_t len = e - i;
		if (len > 0 && s[i + len - 1] == '\r') /* CRLF */
			len--;
		format_line(&b, s + i, len);
		i = e + 1;
	}
	while (b.len > 0 && b.p[b.len - 1] == '\n')
		b.len--;
	if (b.len > 0)
		putc_(&b, '\n');
	put(&b, "", 0);
	return b;
}

/* ---- files ------------------------------------------------------------------------------- */

static buf read_all(FILE *f)
{
	buf b = {0};
	char chunk[65536];
	size_t n;

	while ((n = fread(chunk, 1, sizeof chunk, f)) > 0)
		put(&b, chunk, n);
	put(&b, "", 0);
	return b;
}

int main(int argc, char **argv)
{
	int check = 0, status = 0;

	if (argc > 1 && strcmp(argv[1], "--check") == 0) {
		check = 1;
		argc--, argv++;
	}

	if (argc == 1) {
		buf in = read_all(stdin);
		buf out = format(in.p, in.len);
		if (check)
			return (out.len != in.len || memcmp(out.p, in.p, in.len) != 0);
		fwrite(out.p, 1, out.len, stdout);
		return 0;
	}

	for (int a = 1; a < argc; a++) {
		FILE *f = fopen(argv[a], "rb");
		if (!f) {
			perror(argv[a]);
			status = 2;
			continue;
		}
		buf in = read_all(f);
		fclose(f);

		buf out = format(in.p, in.len);
		int same = (out.len == in.len && memcmp(out.p, in.p, in.len) == 0);
		if (!same && check) {
			printf("%s\n", argv[a]);
			if (status == 0)
				status = 1;
		} else if (!same) {
			f = fopen(argv[a], "wb");
			if (!f || fwrite(out.p, 1, out.len, f) != out.len || fclose(f) != 0) {
				perror(argv[a]);
				status = 2;
			}
		}
		free(in.p);
		free(out.p);
	}
	return status;
}
