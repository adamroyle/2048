import gleeunit/should
import grid

pub fn grid_test() {
  "0 8 2 2 4 32 256 0 2 0 2 0 2 16 32 2"
  |> grid.from_int_string
  |> grid.debug_grid
  |> grid.shift(grid.Left)
  |> grid.debug_grid
  |> grid.to_int_string()
  |> should.equal("8 4 0 0 4 32 256 0 4 0 0 0 2 16 32 2")
}

pub fn change_test() {
  "0 8 2 2"
  |> grid.from_int_string
  //   |> grid.debug_grid
  |> grid.get_changes(grid.Left)
  |> should.equal([
    grid.Move(grid.Cell(id: 1, coord: #(0, 0), value: 8), from: #(0, 1)),
    grid.Move(grid.Cell(id: 2, coord: #(0, 1), value: 2), from: #(0, 2)),
    grid.Merge(
      grid.Cell(id: 3, coord: #(0, 1), value: 4),
      from: #(0, 3),
      with: grid.Cell(id: 2, coord: #(0, 1), value: 2),
    ),
  ])
}
// pub fn grid_second_test() {
//   "2 0 0 0 2 0 0 0 8 0 0 0"
//   |> grid.from_int_string
//   |> grid.debug_grid
//   |> grid.move(grid.Down)
//   |> grid.debug_grid
// }
