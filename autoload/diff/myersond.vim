" EUGENE W. MYERS. 1986. An O(ND) Difference Algorithm and Its Variations
" Nice description (ja).
" http://constellation.hatenablog.com/entry/20091021/1256112978

function diff#myersond#import()
  return s:
endfunction

let s:MyersOnd = {}

function s:MyersOnd.diff(A, B)
  return self.new(a:A, a:B).path
endfunction

function s:MyersOnd.new(...)
  let obj = deepcopy(self)
  call call(obj.__init__, a:000, obj)
  return obj
endfunction

function s:MyersOnd.__init__(A, B)
  let self.A = a:A
  let self.B = a:B
  let self.M = len(a:A)
  let self.N = len(a:B)
  let self.path = self.ond()
endfunction

function s:MyersOnd.ond()
  let [A, M] = [self.A, self.M]
  let [B, N] = [self.B, self.N]

  " NOTE: x or y can be omitted since k = x - y.
  let V = []
  for i in range(N + 1 + M)
    call add(V, {'x': 0, 'y': 0, 'tree': {}})
  endfor

  for D in range(0, N + M)
    for k in range(-D, D, 2)
      if k < -N || M < k
        continue
      endif
      let current = V[k]
      if D == 0
        " start
      elseif k == -D || k != D && V[k - 1].x < V[k + 1].x
        let prev = V[k + 1]
        let current.x = prev.x
        let current.y = prev.y + 1
        let current.tree = {'type': '+', 'prev': prev.tree}
      else
        let prev = V[k - 1]
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
      if x >= M && y >= N
        return self.tree_to_path(current.tree)
      endif
    endfor
  endfor
endfunction

function s:MyersOnd.tree_to_path(tree)
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

