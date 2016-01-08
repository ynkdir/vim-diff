" Sun Wu, Udi Manber, Gene Myers and Webb Miller. 1989.
" "An O(NP) Sequence Comparison Algorithm"
" Nice description (ja).
" http://constellation.hatenablog.com/entry/20091021/1256112978

function diff#wuonp#import()
  return s:
endfunction

" path[x]
"   = 0   common
"   < 0   delete
"   > 0   add
let s:WuOnpDiff = {}

" @static
function s:WuOnpDiff.diff(A, B)
  return self.new(a:A, a:B).path
endfunction

function s:WuOnpDiff.new(...)
  let obj = deepcopy(self)
  call call(obj.__init__, a:000, obj)
  return obj
endfunction

function s:WuOnpDiff.__init__(A, B)
  if len(a:A) >= len(a:B)
    let self.A = a:A
    let self.B = a:B
    let self.M = len(a:A)
    let self.N = len(a:B)
    let self.path = self.onp()
  else
    let self.A = a:B
    let self.B = a:A
    let self.M = len(a:B)
    let self.N = len(a:A)
    let self.path = map(self.onp(), '-v:val')
  endif
endfunction

function s:WuOnpDiff.onp()
  let A = self.A
  let B = self.B
  let M = len(A)
  let N = len(B)
  let D = M - N

  " NOTE: x or y can be omitted since k = x - y.
  let fp = []
  for i in range(N + 1 + M)
    call add(fp, {'x': -1, 'y': -1, 'tree': {}})
  endfor

  let p = -1
  while fp[D].y != N
    let p += 1
    for k in range(-p, D - 1)
      call self.snake(l:)
    endfor
    for k in range(D + p, D + 1, -1)
      call self.snake(l:)
    endfor
    let k = D
    call self.snake(l:)
  endwhile

  return self.tree_to_path(fp[D].tree)
endfunction

function s:WuOnpDiff.snake(l)
  call extend(l:, a:l, 'keep')
  if k < -N || M < k
    return
  endif
  let current = fp[k]
  if p == 0 && k == 0
    " start
    let current.x = 0
    let current.y = 0
  elseif k == -N || k != M && fp[k - 1].y < fp[k + 1].y
    let prev = fp[k + 1]
    let current.x = prev.x
    let current.y = prev.y + 1
    let current.tree = {'type': '+', 'prev': prev.tree}
  else
    let prev = fp[k - 1]
    let current.x = prev.x + 1
    let current.y = prev.y
    let current.tree = {'type': '-', 'prev': prev.tree}
  endif
  let x = current.x
  let y = current.y
  while x < M && y < N && A[x] ==# B[y]
    let current.tree = {'type': '|', 'prev': current.tree}
    let x += 1
    let y += 1
  endwhile
  let current.x = x
  let current.y = y
endfunction

function s:WuOnpDiff.tree_to_path(tree)
  let path = []
  let node = a:tree
  while !empty(node)
    if node.type == '+'
      call insert(path, 1)
    elseif node.type == '-'
      call insert(path, -1)
    else
      call insert(path, 0)
    endif
    let node = node.prev
  endwhile
  return path
endfunction

