import QtQuick
import qs.Ui

// Qt reads the clipboard's text on every clipboard change for each editable
// text input, visible or not (QQuickTextInput::q_canPasteChanged). A slow or
// oversized offer from another app then blocks the whole shell. A read-only
// input skips that read, so the field stays read-only until it has keyboard
// focus and only reads while the user is typing in it.
TextField {
  id: field

  property int keptCursor: -1

  readOnly: !activeFocus

  // Leaving read-only moves the cursor to the end; put it back where the
  // click placed it.
  onCursorPositionChanged: if (field.readOnly) field.keptCursor = field.cursorPosition
  onReadOnlyChanged: {
    if (!field.readOnly && field.keptCursor >= 0 && field.keptCursor <= field.length)
      field.cursorPosition = field.keptCursor
  }
}
