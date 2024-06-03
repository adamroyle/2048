import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result.{is_error}
import gleam/string

pub opaque type Grid {
  Grid(inner: List(Cell), next_id: Int, changes: List(Change), score: Int)
}

pub type Coord =
  #(Int, Int)

pub type Cell {
  Cell(id: Int, coord: Coord, value: Int)
}

pub type Change {
  Move(Cell, from: Coord)
  Merge(Cell, from: Coord, with: Cell)
  Create(Cell)
}

pub type Direction {
  Up
  Down
  Left
  Right
}

pub fn empty() -> Grid {
  Grid(inner: [], next_id: 1, changes: [], score: 0)
}

pub fn new() -> Grid {
  empty()
  |> spawn(random_value())
  |> spawn(random_value())
}

pub fn random_value() -> Int {
  case int.random(100) {
    value if value <= 5 -> 4
    _ -> 2
  }
}

pub fn cell_at(grid: Grid, coord: Coord) -> Result(Cell, Nil) {
  list.find(grid.inner, fn(cell) { cell.coord == coord })
}

pub fn int_to_coord(position: Int) -> Coord {
  #(position / 4, position % 4)
}

pub fn coord_to_int(coord: Coord) -> Int {
  let #(row, col) = coord
  row * 4 + col
}

pub fn get_empty_coord(grid: Grid) -> Result(Coord, Nil) {
  list.range(0, 15)
  |> list.map(int_to_coord)
  |> list.shuffle()
  |> list.find(fn(coord) { cell_at(grid, coord) |> is_error })
}

pub fn spawn(grid: Grid, value: Int) -> Grid {
  case get_empty_coord(grid) {
    Ok(coord) -> spawn_at(grid, coord, value)
    _ -> grid
  }
}

pub fn spawn_at(grid: Grid, coord: Coord, value: Int) -> Grid {
  let cell = Cell(id: grid.next_id, coord: coord, value: value)
  Grid(..grid, inner: [cell, ..grid.inner], next_id: grid.next_id + 1)
}

pub fn update_cell(grid: Grid, cell: Cell) -> Grid {
  Grid(
    ..grid,
    inner: list.map(grid.inner, fn(c) {
      case c.id == cell.id {
        True -> cell
        False -> c
      }
    }),
  )
}

pub fn remove_cell(grid: Grid, cell: Cell) -> Grid {
  Grid(..grid, inner: list.filter(grid.inner, fn(c) { c.id != cell.id }))
}

pub fn score(grid: Grid) -> Int {
  grid.score
}

pub fn get_changes(grid: Grid, direction: Direction) -> List(Change) {
  list.range(0, 4)
  |> list.map(fn(i) {
    case direction {
      Left -> get_changes_left(grid, i)
      Right -> get_changes_right(grid, i)
      Up -> get_changes_up(grid, i)
      Down -> get_changes_down(grid, i)
    }
  })
  |> list.flatten
}

pub fn get_changes_left(grid: Grid, row: Int) -> List(Change) {
  get_row(grid, row)
  |> list.chunk(fn(cell) { cell.value })
  |> list.map(list.sized_chunk(_, 2))
  |> list.flatten
  |> list.index_map(fn(chunk, index) {
    case chunk {
      [a] if a.coord.1 != index -> [
        Move(Cell(..a, coord: #(a.coord.0, index)), from: a.coord),
      ]
      [a, b] if a.coord.1 == index -> [
        Merge(
          Cell(..b, coord: #(b.coord.0, index), value: b.value * 2),
          from: b.coord,
          with: Cell(..a, coord: #(a.coord.0, index)),
        ),
      ]
      [a, b] -> [
        Move(Cell(..a, coord: #(a.coord.0, index)), from: a.coord),
        Merge(
          Cell(..b, coord: #(b.coord.0, index), value: b.value * 2),
          from: b.coord,
          with: Cell(..a, coord: #(a.coord.0, index)),
        ),
      ]
      _ -> []
    }
  })
  |> list.flatten()
}

pub fn get_changes_right(grid: Grid, row: Int) -> List(Change) {
  get_row(grid, row)
  |> list.reverse
  |> list.chunk(fn(cell) { cell.value })
  |> list.map(list.sized_chunk(_, 2))
  |> list.flatten
  |> list.map(list.reverse)
  |> list.reverse
  |> fn(chunks: List(List(Cell))) {
    let num_chunks = list.length(chunks)
    list.index_map(chunks, fn(chunk, index) {
      let i = index + { 4 - num_chunks }
      case chunk {
        [a] if a.coord.1 != i -> [
          Move(Cell(..a, coord: #(a.coord.0, i)), from: a.coord),
        ]
        [b, a] if a.coord.1 == i -> [
          Merge(
            Cell(..b, coord: #(b.coord.0, i), value: b.value * 2),
            from: b.coord,
            with: Cell(..a, coord: #(a.coord.0, i)),
          ),
        ]
        [b, a] -> [
          Merge(
            Cell(..b, coord: #(b.coord.0, i), value: b.value * 2),
            from: b.coord,
            with: Cell(..a, coord: #(a.coord.0, i)),
          ),
          Move(Cell(..a, coord: #(a.coord.0, i)), from: a.coord),
        ]
        _ -> []
      }
    })
  }
  |> list.flatten()
}

pub fn get_changes_up(grid: Grid, col: Int) -> List(Change) {
  get_col(grid, col)
  |> list.chunk(fn(cell) { cell.value })
  |> list.map(list.sized_chunk(_, 2))
  |> list.flatten
  |> list.index_map(fn(chunk, index) {
    case chunk {
      [a] if a.coord.0 != index -> [
        Move(Cell(..a, coord: #(index, a.coord.1)), from: a.coord),
      ]
      [a, b] if a.coord.0 == index -> [
        Merge(
          Cell(..b, coord: #(index, b.coord.1), value: b.value * 2),
          from: b.coord,
          with: Cell(..a, coord: #(index, a.coord.1)),
        ),
      ]
      [a, b] -> [
        Move(Cell(..a, coord: #(index, a.coord.1)), from: a.coord),
        Merge(
          Cell(..b, coord: #(index, b.coord.1), value: b.value * 2),
          from: b.coord,
          with: Cell(..a, coord: #(index, a.coord.1)),
        ),
      ]
      _ -> []
    }
  })
  |> list.flatten()
}

pub fn get_changes_down(grid: Grid, col: Int) -> List(Change) {
  get_col(grid, col)
  |> list.reverse
  |> list.chunk(fn(cell) { cell.value })
  |> list.map(list.sized_chunk(_, 2))
  |> list.flatten
  |> list.map(list.reverse)
  |> list.reverse
  |> fn(chunks: List(List(Cell))) {
    let num_chunks = list.length(chunks)
    list.index_map(chunks, fn(chunk, index) {
      let i = index + { 4 - num_chunks }
      case chunk {
        [a] if a.coord.0 != i -> [
          Move(Cell(..a, coord: #(i, a.coord.1)), from: a.coord),
        ]
        [b, a] if a.coord.0 == i -> [
          Merge(
            Cell(..b, coord: #(i, b.coord.1), value: b.value * 2),
            from: b.coord,
            with: Cell(..a, coord: #(i, a.coord.1)),
          ),
        ]
        [b, a] -> [
          Merge(
            Cell(..b, coord: #(i, b.coord.1), value: b.value * 2),
            from: b.coord,
            with: Cell(..a, coord: #(i, a.coord.1)),
          ),
          Move(Cell(..a, coord: #(i, a.coord.1)), from: a.coord),
        ]
        _ -> []
      }
    })
  }
  |> list.flatten()
}

fn coord_distance(coord1: Coord, coord2: Coord) -> Int {
  let #(row1, col1) = coord1
  let #(row2, col2) = coord2
  int.absolute_value(row1 - row2) + int.absolute_value(col1 - col2)
}

pub fn last_move_distance(grid: Grid, id: Int) -> Int {
  grid.changes
  |> list.find_map(fn(change) {
    case change {
      Move(cell, from) if cell.id == id -> Ok(coord_distance(cell.coord, from))
      Merge(cell, from, _) if cell.id == id ->
        Ok(coord_distance(cell.coord, from))
      _ -> Error(Nil)
    }
  })
  |> result.unwrap(0)
}

fn increment_score(grid: Grid, value: Int) -> Grid {
  Grid(..grid, score: grid.score + value)
}

pub fn apply_changes(grid: Grid, changes: List(Change)) -> Grid {
  list.fold(changes, grid, fn(grid, change) {
    case change {
      Move(cell, _) -> update_cell(grid, cell)
      Merge(cell, _, with) ->
        update_cell(grid, cell)
        |> remove_cell(with)
        |> increment_score(cell.value)
      Create(cell) -> spawn_at(grid, cell.coord, cell.value)
    }
  })
  |> fn(grid) { Grid(..grid, changes: changes) }
}

pub fn get_row(grid: Grid, row: Int) -> List(Cell) {
  list.range(0, 4)
  |> list.filter_map(fn(col) { cell_at(grid, #(row, col)) })
}

pub fn get_col(grid: Grid, col: Int) -> List(Cell) {
  list.range(0, 4)
  |> list.filter_map(fn(row) { cell_at(grid, #(row, col)) })
}

pub fn shift(grid: Grid, direction: Direction) -> Grid {
  let changes = get_changes(grid, direction)
  apply_changes(grid, changes)
}

pub fn move(grid: Grid, direction: Direction) -> Grid {
  let changes = get_changes(grid, direction)
  case changes {
    [] -> grid
    _ -> apply_changes(grid, changes) |> spawn(random_value())
  }
  // let grid = apply_changes(grid, changes)
}

// pub fn get_moves(grid: Grid, direction: Direction) -> List(Move) {
//   do_get_moves(grid, initial_vectors(direction))
// }

// pub fn is_valid_cell(cell: Cell) -> Bool {
//   cell >= 0 && cell <= 15
// }

pub fn empty_cell_count(grid: Grid) -> Int {
  list.range(0, 15)
  |> list.map(int_to_coord)
  |> list.filter(fn(coord) { cell_at(grid, coord) |> is_error })
  |> list.length
}

// fn do_get_moves(grid: Grid, vectors: List(#(Cell, Int))) -> List(Move) {
//   case vectors {
//     [] -> []
//     [vector, ..rest] -> {
//       let #(cell, delta) = vector
//       let value = get_cell_value(grid, cell)
//       let search =
//         [cell + delta * -1, cell + delta * -2, cell + delta * -3]
//         |> list.filter(is_valid_cell)
//         |> list.filter(fn(c) {
//           case delta {
//             1 | -1 -> row(cell) == row(c)
//             4 | -4 -> col(cell) == col(c)
//             _ -> False
//           }
//         })
//         |> list.fold_until(-1, fn(acc, cell) {
//           let val = get_cell_value(grid, cell)
//           case value, val {
//             Empty, Value(_) -> list.Stop(cell)
//             Value(a), Value(b) if a == b -> list.Stop(cell)
//             Value(_), Value(_) -> list.Stop(acc)
//             _, _ -> list.Continue(acc)
//           }
//         })

//       case is_valid_cell(search) {
//         True -> {
//           let move = Move(from: search, to: cell)
//           // io.debug(move)
//           let grid = apply_moves(grid, [move])
//           let next_cell = {
//             case value {
//               Empty -> cell
//               Value(_) -> cell + delta * -1
//             }
//           }
//           let rest = {
//             case is_valid_cell(next_cell) {
//               True -> [#(next_cell, delta), ..rest]
//               False -> rest
//             }
//           }
//           [move, ..do_get_moves(grid, rest)]
//         }
//         False -> {
//           case value {
//             Empty -> do_get_moves(grid, rest)
//             _ -> {
//               let next_cell = cell + delta * -1
//               let rest = {
//                 case is_valid_cell(next_cell) {
//                   True -> [#(next_cell, delta), ..rest]
//                   False -> rest
//                 }
//               }
//               do_get_moves(grid, rest)
//             }
//           }
//         }
//       }
//     }
//   }
// }

// pub fn apply_moves(grid: Grid, moves: List(Move)) -> Grid {
//   list.fold(moves, grid, fn(grid, move) {
//     let value = get_cell_value(grid, move.from)
//     case get_cell_value(grid, move.to) {
//       Value(v) -> set_cell(grid, move.to, Value(v * 2))
//       Empty -> set_cell(grid, move.to, value)
//     }
//     |> set_cell(move.from, Empty)
//   })
// }

// pub fn is_complete(grid: Grid) -> Bool {
//   get_moves(grid, Up) == []
//   && get_moves(grid, Down) == []
//   && get_moves(grid, Left) == []
//   && get_moves(grid, Right) == []
// }

// fn initial_vectors(direction: Direction) -> List(#(Int, Int)) {
//   case direction {
//     Up -> [#(0, -4), #(1, -4), #(2, -4), #(3, -4)]
//     Down -> [#(12, 4), #(13, 4), #(14, 4), #(15, 4)]
//     Left -> [#(0, -1), #(4, -1), #(8, -1), #(12, -1)]
//     Right -> [#(3, 1), #(7, 1), #(11, 1), #(15, 1)]
//   }
// }

pub fn to_list(grid: Grid) -> List(Option(Cell)) {
  list.range(0, 15)
  |> list.map(int_to_coord)
  |> list.map(cell_at(grid, _))
  |> list.map(option.from_result)
}

pub fn to_string(grid: Grid) {
  let tmpl =
    "
┏━━━━┯━━━━┯━━━━┯━━━━┓
┃....│....│....│....┃
┠────┼────┼────┼────┨
┃....│....│....│....┃
┠────┼────┼────┼────┨
┃....│....│....│....┃
┠────┼────┼────┼────┨
┃....│....│....│....┃
┗━━━━┷━━━━┷━━━━┷━━━━┛
"
    |> string.drop_left(1)
  let tmpl_list = string.split(tmpl, "....")
  let grid_list =
    to_list(grid)
    |> list.map(fn(value) {
      case value {
        Some(cell) -> pad_string(int.to_string(cell.value))
        None -> "    "
      }
    })

  list.interleave([tmpl_list, grid_list])
  |> string.join("")
}

fn pad_string(str: String) -> String {
  case string.length(str) {
    1 -> "  " <> str <> " "
    2 -> " " <> str <> " "
    3 -> " " <> str
    _ -> str
  }
}

// pub fn to_string2(grid: Grid, f: fn(Cell, Coord) -> String) {
//   let tmpl =
//     "
// ┏━━━━┯━━━━┯━━━━┯━━━━┓
// ┃....│....|....│....┃
// ┠────┼────┼────┼────┨
// ┃....│....|....│....┃
// ┠────┼────┼────┼────┨
// ┃....│....|....│....┃
// ┠────┼────┼────┼────┨
// ┃....│....|....│....┃
// ┗━━━━┷━━━━┷━━━━┷━━━━┛
// "
//     |> string.drop_left(1)
//   let tmpl_list = string.split(tmpl, "....")
//   let grid_list =
//     to_list(grid)
//     |> list.map(fn(v) { f(v.1, v.0) })
//   // |> string.pad_left(2, " ")
//   // |> string.pad_right(3, " ")
//   list.interleave([tmpl_list, grid_list])
//   |> string.join("")
// }

pub fn debug_grid(grid: Grid) {
  let formatted = to_string(grid)
  io.println_error(formatted)
  //   io.debug(grid)
  grid
}

pub fn to_int_list(grid: Grid) -> List(Int) {
  to_list(grid)
  |> list.map(fn(option) {
    case option {
      Some(cell) -> cell.value
      None -> 0
    }
  })
}

pub fn from_int_list(list: List(Int)) -> Grid {
  list.index_fold(list, empty(), fn(grid, value, position) {
    case value {
      0 -> grid
      _ -> spawn_at(grid, int_to_coord(position), value)
    }
  })
}

pub fn to_int_string(grid: Grid) -> String {
  to_int_list(grid)
  |> list.map(int.to_string)
  |> string.join(" ")
}

pub fn from_int_string(str: String) -> Grid {
  str
  |> string.split(" ")
  |> list.map(int.parse)
  |> list.map(result.unwrap(_, 0))
  |> from_int_list
}
