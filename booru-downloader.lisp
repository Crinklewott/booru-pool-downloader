(in-package :io.github.thingywhat.booru-downloader)

(defun download-pool (url &key (start 0) folder)
  "Downloads a pool of Booru images from a URL. Optionatlly puts them
into a folder. Accepts the following arguments:

  url: The URL of the pool of Booru images to download.

Keywords arguments:

  start: The starting number to download files with. (It's default is
  zero) This means that if you download a pool of five images, and set
  this to 1, you will get images titled like: 0001_<some id>.png,
  0002_<some id>.png and so on to 0005_<some id>.png instead of
  starting at 0000_<some id>.png and going to 0004_<some id>.png.

  folder: The folder to download all of the pool images into."
  (let ((count start)
        (content (http-request url))
        (root-url (scan-to-strings "[^:]+://[^/]+" url)))

    ;; Grabs the URLs for the images on the fetched gallery page and
    ;; downloads them
    (do-register-groups (file-url extension id)
        ("\"file_url\":\"([^\"]+)(\\.[^\"]+)\",\"id\":(\\d+)" content)
      (let* ((filename (format nil "~4,'0D_~D~a" count id extension))
             (file-url (concatenate 'string file-url extension))
             (image (http-request file-url)))
        (print (concatenate 'string "Downloading " file-url " to " filename))
        (incf count)
        (with-open-file (file (make-pathname :directory folder :name filename)
                              :direction :output
                              :if-exists :supersede
                              :element-type '(unsigned-byte 8))
          (loop for byte across image do (write-byte byte file)))))

    ;; Looks for a next page, and recurses with the current image
    ;; count as the starting count for the next iteration.
    (do-register-groups (next-page)
        ("<a href=\"([^\"]+)\" >&gt;&gt;</a>" content)
      (let ((pool (concatenate 'string
                               (when (eql #\/ (car (coerce next-page 'list))) root-url)
                               next-page)))
        (download-pool pool :start count)))))


(defun draw-interface ()
  "Draws the interface for the downloader and starts the LTK event
loop. This function will create the main window, and can serve as an
image entrypoint for built Lisp images."
  (let ((*wish-args* '("-name" "Booru Image Pool Downloader")))
    (with-ltk ()
      (let* ((frame (make-instance 'frame))
             (url-label (make-instance 'label :text "Pool URL:" :master frame))
             (destination-label (make-instance 'label :text "Destination:" :master frame))

             ;; The input that contains the URL of the place we are
             ;; downloading the images from.
             (url-input (make-instance 'entry :master frame))

             ;; The input that contains the location images will be
             ;; downloaded to.
             (destination-input (make-instance 'entry :master frame))

             ;; The button that will initiate the download using the
             ;; values in the url-input as the souce, and the
             ;; destination-input as the target.
             (download-button
              (make-instance
               'button
               :master frame
               :text "Download!"
               :command (lambda ()
                          (if (equal (text url-input) "")
                              (message-box "You should probably enter a Pool URL, hey?"
                                           "Can't download empty URL")
                              (download-pool (text url-input)
                                             :folder (text destination-input))))))

             ;; The button to pick a folder for the destination-input
             ;; field. This is the place all images will be downloaded
             ;; to.
             (browse-button
              (make-instance
               'button
               :master frame
               :text "Browse"
               :command (lambda ()
                          (setf (text destination-input)
                                (choose-directory :parent frame
                                                  :title "Pick a destination"
                                                  :mustexist t)))))

             ;; A button that exits the window, and if this function is
             ;; the entrypoint into the Lisp image: closes the program
             ;; altogether.
             (quit-button
              (make-instance
               'button
               :master frame
               :text "Quit"
               :command #'exit-wish)))

        ;; Interface layout logic
        (grid frame 0 0 :padx 10 :pady 10)
        (grid url-label 0 0)
        (grid url-input 0 1 :ipady 2 :pady 3 :padx 5 :sticky :ew :columnspan 2)
        (grid destination-label 1 0)
        (grid destination-input 1 1 :ipady 2 :pady 3 :padx 5)
        (grid browse-button 1 2)
        (grid download-button 2 0 :pady 5)
        (grid quit-button 2 2 :pady 2)
        (resizable *tk* 0 0)))))
