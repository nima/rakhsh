; rx-louder C/C++ block tag highlights (NON-DOXY ONLY)
; We ONLY tag plain block comments:  /*+  /*-  /*=  ...
; We DO NOT touch Doxygen blocks that begin with `/**`.
; Highlight only the 3-char marker `/*X` so we don't override the comment body.

((comment) @c @comment.tag.title
  (#lua-match? @c "^%s*/%*=%s")
  (#offset! @comment.tag.title 0 0 0 3))

((comment) @c @comment.tag.notice
  (#lua-match? @c "^%s*/%*%-%s")
  (#offset! @comment.tag.notice 0 0 0 3))

((comment) @c @comment.tag.probing
  (#lua-match? @c "^%s*/%*%?%s")
  (#offset! @comment.tag.probing 0 0 0 3))

((comment) @c @comment.tag.fyi
  (#lua-match? @c "^%s*/%*%+%s")
  (#offset! @comment.tag.fyi 0 0 0 3))

((comment) @c @comment.tag.staged
  (#lua-match? @c "^%s*/%*&%s")
  (#offset! @comment.tag.staged 0 0 0 3))

((comment) @c @comment.tag.upstream
  (#lua-match? @c "^%s*/%*<%s")
  (#offset! @comment.tag.upstream 0 0 0 3))

((comment) @c @comment.tag.downstream
  (#lua-match? @c "^%s*/%*>%s")
  (#offset! @comment.tag.downstream 0 0 0 3))

((comment) @c @comment.tag.attention
  (#lua-match? @c "^%s*/%*!%s")
  (#offset! @comment.tag.attention 0 0 0 3))

((comment) @c @comment.tag.reference
  (#lua-match? @c "^%s*/%*@%s")
  (#offset! @comment.tag.reference 0 0 0 3))

((comment) @c @comment.tag.cost
  (#lua-match? @c "^%s*/%*%$%s")
  (#offset! @comment.tag.cost 0 0 0 3))

((comment) @c @comment.tag.onotation
  (#lua-match? @c "^%s*/%*O%s")
  (#offset! @comment.tag.onotation 0 0 0 3))

((comment) @c @comment.tag.deprecation
  (#lua-match? @c "^%s*/%*~%s")
  (#offset! @comment.tag.deprecation 0 0 0 3))