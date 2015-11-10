(asdf:defsystem "booru-downloader"
  :description "A Booru-based site downloader"
  :version "0.0.1"
  :author "thingywhat <thingywhat@gmail.com>"
  :license "MIT"
  :depends-on (:ltk :drakma :cl-ppcre)
  :components ((:file "packages")
               (:file "booru-downloader")))
