export function register_document_keydown(func) {
  window.document.onkeydown = (event) => {
    func(event.key);
  };
}
