const vscode = require('vscode');
const { find, markdown, localLabel } = require('./lookup');

const SELECTOR = { language: 'z80-macroasm', scheme: 'file' };

exports.activate = (context) => {
  context.subscriptions.push(
    vscode.languages.registerHoverProvider(SELECTOR, {
      provideHover(document, position) {
        const found = find(document.lineAt(position.line).text);
        if (!found || position.character < found.start || position.character > found.end) return undefined;
        return new vscode.Hover(new vscode.MarkdownString(markdown(found)),
          new vscode.Range(position.line, found.start, position.line, found.end));
      },
    }),
    vscode.languages.registerDefinitionProvider(SELECTOR, {
      provideDefinition(document, position) {
        const range = document.getWordRangeAtPosition(position, /\b\d+\$/);
        if (!range) return undefined;
        const lines = document.getText().split(/\r?\n/);
        const line = localLabel(lines, position.line, document.getText(range));
        return line === undefined ? undefined : new vscode.Location(document.uri, new vscode.Position(line, 0));
      },
    }),
  );
};
