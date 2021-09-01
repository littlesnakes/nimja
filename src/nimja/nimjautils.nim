import options
export options
type
  Loop*[T] = object
    index*: int ## which element (start from 1)
    index0*: int ## which elemen (start from 0)
    first*: bool ## if this is the first loop iteration
    last*: bool ## if this is the last loop iteration
    previtem*: Option[T] ## get the item from the last loop iteration
    nextitem*: Option[T] ## get the item from the next loop iteration
    length*: int ## the length of the seq, (same as mySeq.len())
    revindex0*: int ## which element, counted from the end (last one is 0)
    revindex*: int ## which element, counted from the end (last one is 1)
  Loopable*[T] = concept x {.explain.}
    x.len() is int
    x[int] is T
    x.items is T


proc cycle*[T](loop: Loop, elems: openArray[T]): T =
  ## within a loop you can cycle through elements:
  ##
  ## .. code-block:: Nim
  ##   {% for (loop, row) in rows.loop() %}
  ##       <li class="{{ loop.cycle(@["odd", "even"]) }}">{{ row }}</li>
  ##   {% endfor %}
  ##
  return elems[loop.index0 mod elems.len]

iterator loop*[T](a: Loopable[T]): tuple[loop: Loop[T], val: T] = # TODO cannot access fields in the template; why?
# iterator loop*[T](a: openArray[T]): tuple[loop: Loop[T], val: T] {.inline.} =
  ## yields a `Loop` object with every item.
  ## Inside the loop body you have access to the following fields.
  ##
  ## .. code-block:: Nim
  ##   {% for (loop, row) in rows.loop() %}
  ##       {{ loop.index0 }}
  ##       {{ loop.index }}
  ##       {{ loop.revindex0 }}
  ##       {{ loop.revindex }}
  ##       {{ loop.length }}
  ##       {% if loop.first %}The first item{% endif %}
  ##       {% if loop.last %}The last item{% endif %}
  ##       {% if loop.previtem.isSome() %}{{ loop.previtem.get() }}{% endif %}
  ##       {% if loop.nextitem.isSome() %}{{ loop.nextitem.get() }}{% endif %}
  ##       <li class="{{ loop.cycle(@["odd", "even"]) }}">{{row}}</li>
  ##   {% endfor %}
  ##
  # TODO this should be a concept, but does not work why?
  # however, the element you iterate over must match the Concept `Loopable`.
  # This means you can propably not use loop() with an iterator, since they do not have a `len()` and `[]`
  var idx = 0
  for each in a:
    var loop = Loop[T]()
    loop.index = idx + 1
    loop.index0 = idx
    loop.first = idx == 0
    loop.last = idx == a.len() - 1
    if not loop.first:
      loop.previtem = some(a[idx - 1])
    if not loop.last:
      loop.nextitem = some(a[idx + 1])
    loop.length = a.len()
    loop.revindex0 = a.len() - (idx + 1)
    loop.revindex = a.len() - idx
    idx.inc
    yield (loop, each)


when isMainModule:

  for loop, elem in @["foo", "baa", "baz"].loop():
    if loop.first:
      echo "<ul>"
    echo "<li class=\"" & loop.cycle(@["odd", "even"]) & "\">",loop.index0, " ", loop.index, " " , elem, " ", loop.revindex, " ", loop.revindex0, "</li>", loop.cycle(["1", "2","foo"])
    if loop.last:
      echo "</ul>"

  import nimja
  proc foo(rows: seq[string]): string =
    compileTemplateStr("""
{% for (loop, row) in rows.loop() %}
  <div class="row">
    {{row}}
    {{ loop.index0 }}
    {{ loop.index }}
    {{ loop.revindex0 }}
    {{ loop.revindex }}
    {{ loop.length }}
    {% if loop.first %}The first item{% endif %}
    {% if loop.last %}The last item{% endif %}
    {% if loop.previtem.isSome() %}{{ loop.previtem.get() }}{% endif %}
    {% if loop.nextitem.isSome() %}{{ loop.nextitem.get() }}{% endif %}
    <li class="{{ loop.cycle(@["odd", "even"]) }}">{{row}}</li>
  </div>
{% endfor %}
    """)
  echo foo(@["foo","baa", "baz"])