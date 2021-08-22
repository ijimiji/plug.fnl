(var plug-keywords [:config :setup :theme :branch :tag :bind :fetcher])
(var plug-packages [])

(fn map [tbl f]
  (let [new-tbl []]
    (each [k v (pairs tbl)]
      (tset new-tbl k (f v)))
    new-tbl))

(fn imap [tbl f]
  (let [new-tbl []]
    (each [k v (ipairs tbl)]
      (tset new-tbl k (f v)))
    new-tbl))

(local fmt string.format)
(local std-path (.. (vim.fn.stdpath :data) :/site/pack/plug.fnl/))
(fn split [s pat]
  "Split the given string into a sequential table using the pattern."
  (var done? false)
  (var acc [])
  (var index 1)
  (while (not done?)
    (let [(start end) (string.find s pat index)]
      (if (= :nil (type start))
        (do
          (table.insert acc (string.sub s index))
          (set done? true))
        (do
          (table.insert acc (string.sub s index (- start 1)))
          (set index (+ end 1))))))
  acc)
(fn ensure-package [options]
  (local [owner repo] (split (. options :owner/repo) :/))
  (local tag (?. options :tag 1))
  (local fetcher (?. options :fetcher))
  (local install-path (.. std-path 
                          (or (?. options :opt/ 1) :start/) repo))
  (local git-args [:clone 
                   :--depth=1 
                   :--recurse-submodules 
                   :--shallow-submodules 
                   (if tag (.. "-b " tag))])
  ;; Check if repo is installed
  ;; If zero, file exists
  ;; Otherwise it doesn't
  (match (vim.fn.empty (vim.fn.glob install-path))
    0 true
    _ (vim.cmd 
        (fmt "!git %s https://%s/%s/%s %s" 
             (table.concat git-args " ")
             (or fetcher :github.com)
             owner
             repo
             install-path)))
  ;; Install docs
  (if (= (vim.fn.empty (vim.fn.glob (.. install-path :/doc))) 0)
    (vim.cmd (fmt "helptags %s/doc" install-path)))
  ;; Install package
  (vim.cmd 
    (fmt "packadd %s" repo)))

(fn pack [...]
  (doto [...]
    (tset :n (select "#" ...))))

(fn member? [tbl ref]
  (each [key val (pairs tbl)]
    (when (= val ref)
      (lua "return true"))))

(fn parse-arg-list [...]
  (var args (pack ...))
  (var new-table {})
  (var last-keyword "")
  (for [i 1 args.n]
    (local arg (. args i))
    (if (member? plug-keywords arg)
      (do (set last-keyword arg)
        (tset new-table last-keyword []))
      (table.insert (. new-table last-keyword) arg)))
  new-table)

(fn setup-colors [options]
  (let [theme (?. options :theme 1)]
    (if theme
      (vim.cmd (.. "colorscheme " theme)))))

(fn setup-options [options]
  (let [setup-function (?. options :setup 1)]
    (if setup-function
      (setup-function))))

(fn plug [owner/repo ...]
  (let [options (parse-arg-list ...)]
    (tset options :owner/repo owner/repo)
    (ensure-package options)
    (setup-colors options)
    (setup-options options)))
