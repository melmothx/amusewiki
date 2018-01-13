$(document).ready(function() {
    $('#attachment').change(function() {
        var target = $(this).data('upload-url');
        if (target) {
            $(this).simpleUpload(target, {
                start: function(file) {
				    //upload started
				    this.block = $("<div/>", { 'class': 'upload-item  col-sm-6 col-md-4' });
				    this.progressBar = $('<div/>', { class: "progress-bar",
                                                     role: "progressbar",
                                                     style: "width: 1%" });
                    this.progressBar.text('0%');
				    this.block.append(this.progressBar);
				    $('#uploads').append(this.block);
			    },
			    progress: function(progress) {
				    //received progress
                    console.log("Progress: " + progress);
				    this.progressBar.css("width", progress + "%");
                    this.progressBar.text(progress + "%");
			    },
			    success: function(data) {
				    //upload successful
				    this.progressBar.remove();
                    console.log(data);
				    if (data.uris) {
                        for (var i = 0; i < data.uris.length; i++) {
                            var uri = data.uris[i];
                            var img;
                            if (uri.match(/\.(png|jpe?g)$/)) {
                                img = $('<img/>', {
                                    class: "img-responsive img-thumbnail",
                                    src: uri,
                                    alt: uri }
                                );
                            }
                            else {
                                img = $('<span/>', { class: "fa fa-file-pdf-o fa-2x fa-border" });
                            }
					        this.block.append(
                                $('<div/>', { class: "thumbnail" }).append(
                                    img,
                                    $('<div/>', { class: "caption" }).append(
                                        $('<code/>').text(uri)
                                    )
                                )
                            );
                        }
				    } else {
					    //our application returned an error
					    var error = data.error.message;
					    var errorDiv = $('<div class="error"></div>').text(error);
					    this.block.append(errorDiv);
				    }
			    },
			    error: function(error) {
				    //upload failed
                    console.log(error);
				    this.progressBar.remove();
				    var error = error.message;
				    var errorDiv = $('<div class="error"></div>').text(error);
				    this.block.append(errorDiv);
			    }
		    });
        }
    });
});
