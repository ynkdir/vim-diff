function diff#normal#import()
  return s:
endfunction

let s:Normal = {}

let s:Normal.NOEOL = '\ No newline at end of file'

function s:Normal.format(path, A, Aeol, B, Beol)
  let base = 1
  let lines = []
  for [oldstart, oldcount, newstart, newcount] in self.reduce(a:path)
    if oldcount == 0
      let oldrange = printf('%d', oldstart)
    elseif oldcount == 1
      let oldrange = printf('%d', oldstart + base)
    else
      let oldrange = printf('%d,%d', oldstart + base, oldstart + base + oldcount - 1)
    endif
    if newcount == 0
      let newrange = printf('%d', newstart)
    elseif newcount == 1
      let newrange = printf('%d', newstart + base)
    else
      let newrange = printf('%d,%d', newstart + base, newstart + base + newcount - 1)
    endif
    if oldcount == 0
      call add(lines, printf('%sa%s', oldrange, newrange))
      for i in range(newcount)
        call add(lines, printf('> %s', a:B[newstart + i]))
      endfor
      if !a:Beol && newstart + newcount == len(a:B)
        call add(lines, self.NOEOL)
      endif
    elseif newcount == 0
      call add(lines, printf('%sd%s', oldrange, newrange))
      for i in range(oldcount)
        call add(lines, printf('< %s', a:A[oldstart + i]))
      endfor
      if !a:Aeol && oldstart + oldcount == len(a:A)
        call add(lines, self.NOEOL)
      endif
    else
      call add(lines, printf('%sc%s', oldrange, newrange))
      for i in range(oldcount)
        call add(lines, printf('< %s', a:A[oldstart + i]))
      endfor
      if !a:Aeol && oldstart + oldcount == len(a:A)
        call add(lines, self.NOEOL)
      endif
      call add(lines, '---')
      for i in range(newcount)
        call add(lines, printf('> %s', a:B[newstart + i]))
      endfor
      if !a:Beol && newstart + newcount == len(a:B)
        call add(lines, self.NOEOL)
      endif
    endif
  endfor
  return lines
endfunction

function s:Normal.reduce(path)
  let diffs = []
  let x = 0
  let y = 0
  let i = 0
  while i < len(a:path)
    if a:path[i] == 0
      let i += 1
      let x += 1
      let y += 1
    elseif a:path[i] > 0
      let oldstart = y
      let oldcount = 0
      let newstart = x
      let newcount = 0
      while i < len(a:path) && a:path[i] > 0
        let newcount += 1
        let i += 1
      endwhile
      while i < len(a:path) && a:path[i] < 0
        let oldcount += 1
        let i += 1
      endwhile
      let y += oldcount
      let x += newcount
      call add(diffs, [oldstart, oldcount, newstart, newcount])
    elseif a:path[i] < 0
      let oldstart = y
      let oldcount = 0
      let newstart = x
      let newcount = 0
      while i < len(a:path) && a:path[i] < 0
        let oldcount += 1
        let i += 1
      endwhile
      while i < len(a:path) && a:path[i] > 0
        let newcount += 1
        let i += 1
      endwhile
      let y += oldcount
      let x += newcount
      call add(diffs, [oldstart, oldcount, newstart, newcount])
    endif
  endwhile
  return diffs
endfunction
