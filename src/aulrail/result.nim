import
  options

import
  types


type Result*[T] = object
  result*: T
  error*: Option[Error]


func isOk*(res: Result): bool = res.error.isNone
