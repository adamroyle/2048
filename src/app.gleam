import gleam/int
import gleam/list
import gleam/option
import gleam/pair
import gleam/string
import grid
import lustre
import lustre/attribute
import lustre/effect.{type Effect, batch}
import lustre/element
import lustre/element/html

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

pub type Model =
  grid.Grid

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(
    grid.new(),
    batch([register_document_keydown(), read_localstorage("high_score")]),
  )
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  UserPressedKey(String)
  HighScoreRead(Result(String, Nil))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserPressedKey(key) -> {
      case key {
        "ArrowUp" -> grid.move(model, grid.Up)
        "ArrowDown" -> grid.move(model, grid.Down)
        "ArrowLeft" -> grid.move(model, grid.Left)
        "ArrowRight" -> grid.move(model, grid.Right)
        _ -> model
      }
      |> pair.new(write_localstorage(
        "high_score",
        grid.get_high_score(model) |> int.to_string,
      ))
    }
    HighScoreRead(Ok(value)) -> {
      case int.parse(value) {
        Ok(value) -> grid.set_high_score(model, value)
        Error(_) -> model
      }
      |> pair.new(effect.none())
    }
    _ -> model |> pair.new(effect.none())
  }
}

fn register_document_keydown() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_register_document_keydown(fn(key) { dispatch(UserPressedKey(key)) })
  })
}

@external(javascript, "./app.ffi.mjs", "register_document_keydown")
fn do_register_document_keydown(func: fn(String) -> Nil) -> Nil

fn read_localstorage(key: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_read_localstorage(key)
    |> HighScoreRead
    |> dispatch
  })
}

@external(javascript, "./app.ffi.mjs", "read_localstorage")
fn do_read_localstorage(_key: String) -> Result(String, Nil) {
  Error(Nil)
}

fn write_localstorage(key: String, value: String) -> Effect(msg) {
  effect.from(fn(_) { do_write_localstorage(key, value) })
}

@external(javascript, "./app.ffi.mjs", "write_localstorage")
fn do_write_localstorage(_key: String, _value: String) -> Nil {
  Nil
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> element.Element(Msg) {
  html.div([], [
    html.div(
      [attribute.class("flex justify-between w-[22.5rem] mx-auto my-16")],
      [
        html.div(
          [
            attribute.class(
              "bg-[#DEC14C] text-[#FFFFFF] aspect-square p-2 font-bold rounded-md flex items-center justify-center text-2xl",
            ),
          ],
          [html.text("2048")],
        ),
        html.div([attribute.class("flex gap-2")], [
          html.div([attribute.class("bg-[#B8ADA1] rounded-md w-20 pt-4")], [
            html.div([], [
              html.div(
                [
                  attribute.class(
                    "text-[#ECE4DB] text-center text-sm font-bold",
                  ),
                ],
                [html.text("SCORE")],
              ),
              html.div(
                [attribute.class("text-white text-center text-lg font-bold")],
                [html.text(grid.score(model) |> int.to_string)],
              ),
            ]),
          ]),
          html.div([attribute.class("bg-[#B8ADA1] rounded-md w-20 pt-4")], [
            html.div([], [
              html.div(
                [
                  attribute.class(
                    "text-[#ECE4DB] text-center text-sm font-bold",
                  ),
                ],
                [html.text("BEST")],
              ),
              html.div(
                [attribute.class("text-white text-center text-lg font-bold")],
                [html.text(grid.get_high_score(model) |> int.to_string)],
              ),
            ]),
          ]),
        ]),
      ],
    ),
    html.div(
      [
        attribute.class(
          "relative w-[22.5rem] mx-auto my-16 bg-[#B8ADA1] rounded-lg p-2",
        ),
      ],
      [
        html.div(
          [attribute.class("grid grid-cols-4 gap-2")],
          list.range(0, 15)
            |> list.map(fn(_) {
              html.div(
                [attribute.class("w-20 bg-[#C9C0B5] aspect-square rounded-md")],
                [],
              )
            }),
        ),
        element.keyed(html.div([attribute.class("absolute inset-2")], _), {
          grid.to_list(model)
          |> list.filter_map(option.to_result(_, ""))
          |> list.sort(fn(a, b) { int.compare(a.id, b.id) })
          |> list.map(fn(cell) {
            let value = cell.value
            let text = cell.value |> int.to_string
            let id = cell.id |> int.to_string
            #(
              id,
              html.div(
                [
                  attribute.classes([
                    #(
                      "absolute w-20 transition-all aspect-square flex items-center justify-center font-bold rounded-md",
                      True,
                    ),
                    #(
                      case grid.last_move_distance(model, cell.id) {
                        1 -> "duration-200"
                        2 -> "duration-300"
                        3 -> "duration-[400ms]"
                        _ -> "duration-200"
                      },
                      True,
                    ),
                    #(
                      case cell.coord.0 {
                        1 -> "top-[5.5rem]"
                        2 -> "top-[11rem]"
                        3 -> "top-[16.5rem]"
                        _ -> "top-0"
                      },
                      True,
                    ),
                    #(
                      case cell.coord.1 {
                        1 -> "left-[5.5rem]"
                        2 -> "left-[11rem]"
                        3 -> "left-[16.5rem]"
                        _ -> "left-0"
                      },
                      True,
                    ),
                    #("bg-[#ECE4DB] text-[#756E66]", value == 2),
                    #("bg-[#EAE0CA] text-[#756E66]", value == 4),
                    #("bg-[#E8B381] text-[#FFFFFF]", value == 8),
                    #("bg-[#DF915F] text-[#FFFFFF]", value == 16),
                    #("bg-[#E68266] text-[#FFFFFF]", value == 32),
                    #("bg-[#D96243] text-[#FFFFFF]", value == 64),
                    #("bg-[#EED97B] text-[#FFFFFF]", value == 128),
                    #("bg-[#EBD163] text-[#FFFFFF]", value == 256),
                    #("bg-[#DEC14C] text-[#FFFFFF]", value == 512),
                    #("bg-[#DEC14C] text-[#FFFFFF]", value == 1024),
                    #("bg-[#DEC14C] text-[#FFFFFF]", value == 2048),
                    #("text-4xl", string.length(text) <= 2),
                    #("text-3xl", string.length(text) == 3),
                    #("text-2xl", string.length(text) == 4),
                    #("scale-0 animate-pop-in", string.length(text) > 0),
                  ]),
                ],
                [html.text(text)],
              ),
            )
          })
        }),
      ],
    ),
  ])
}
