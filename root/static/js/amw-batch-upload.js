$(document).ready(function() {
    $('#attachment').change(function() {
        var target = $(this).data('upload-url');
        if (target) {
            $(this).simpleUpload(target, {
                start: function(file){
				    //upload started
				    this.block = $('<div class="block"></div>');
				    this.progressBar = $('<div class="progressBar"></div>');
				    this.block.append(this.progressBar);
				    $('#uploads').append(this.block);
			    },
			    progress: function(progress){
				    //received progress
				    this.progressBar.width(progress + "%");
			    },
			    success: function(data){
				    //upload successful
				    this.progressBar.remove();
                    console.log(data);
				    if (data.uris) {
                        for (var i = 0; i < data.uris.length; i++) {
                            var uri = data.uris[i];
					        var formatDiv = $('<div class="format"></div>').text(uri);
					        this.block.append(formatDiv);
                        }
				    } else {
					    //our application returned an error
					    var error = data.error.message;
					    var errorDiv = $('<div class="error"></div>').text(error);
					    this.block.append(errorDiv);
				    }
			    },
			    error: function(error){
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
