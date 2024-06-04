import { Ok, Error } from "./gleam.mjs";

export function register_document_keydown(func) {
  window.document.onkeydown = (event) => {
    func(event.key);
  };
}

export function read_localstorage(key) {
  const value = window.localStorage.getItem(key);

  return value ? new Ok(value) : new Error(undefined);
}

export function write_localstorage(key, value) {
  window.localStorage.setItem(key, value);
}
