/*
 * Copyright 2015, Michael Brook, All rights reserved.
 * http://simpleupload.michaelcbrook.com/
 *
 * simpleUpload.js is an extremely simple yet powerful jQuery file upload plugin.
 * It is free to use under the MIT License (http://opensource.org/licenses/MIT)
 *
 * https://github.com/michaelcbrook/simpleUpload.js
 * @michaelcbrook
 */

function simpleUpload(ajax_url, DOM_file, options)
{

var forceIframe = false;

var files = null; //files object for HTML5 uploads (if applicable)
var limit = 0; //the max number of files that can be uploaded from this selection (0 = no limit)

var max_file_size = 0; //max file size for an uploaded file in bytes
var allowed_exts = []; //array of allowed file extensions for an uploaded file
var allowed_types = []; //array of allowed MIME types for an uploaded file
var expect_type = "auto"; //the type of result to expect (can either be auto, json, xml, html, script, or text)

var hash_worker = null; //file path (relative to page) to hash worker javascript file
var on_hash_complete = null; //function(hash, callbacks){ callbacks.proceed(); //success(), proceed(), or error() }; //called when hash is calculated for a file, the next step is determined by the callback that is called

var request_file_name = "file"; //name of file to be uploaded (should be the same as DOM_file's name)
var request_data = {}; //additional data to get passed to the backend script with the file upload

var xhrFields = {}; //object of field name/value pairs to send with ajax request (set on native XHR object) - { withCredentials: true } is one example

//default callback functions
var on_init_callback = function(total_uploads){}; //on initialization of instance, given at least one file is queued for upload (can cancel all uploads or set limit by returning either false or an integer, respectively)
var on_start_callback = function(file){}; //on beginning of each file upload (can return false to exclude this file from being uploaded)
var on_progress_callback = function(progress){}; //on upload progress update
var on_success_callback = function(data){}; //on successful file upload
var on_error_callback = function(error){}; //on failed file upload
var on_cancel_callback = function(){}; //on cancelled upload (via this.upload.cancel())
var on_complete_callback = function(status){}; //on completed upload, regardless of success
var on_finish_callback = function(){}; //on completion of all file uploads for this instance, regardless of success

var upload_contexts = []; //an array containing objects for each file upload that can be referenced inside each callback using "this"
var private_upload_data = []; //same as above, except the properties of these objects are not accessible via "this"
var instance_context = { files: upload_contexts }; //an instance-specific context for "this" to pass to non-file-specific events like init() and finish()

var queued_files = 0; //number of files remaining in the queue for this instance
var hidden_form = null; //jquery object containing hidden form appended to body of page, which contains the moved DOM_file, if it exists



//helper function to run after every success, error, or cancel event

var file_completed = function(upload_num, status){

  on_complete(upload_num, status);

  queued_files--;

    if (queued_files==0)
      on_finish();

  simpleUpload.activeUploads--;
  simpleUpload.uploadNext();

};

/* Wrappers to the callback functions that additionally perform internal functions */

var on_init = function(total_uploads){

  return on_init_callback.call(instance_context, total_uploads);

};

var on_start = function(upload_num, file){

    if (getUploadState(upload_num) > 0) //if cancelled via the init function, don't start upload
      return false;

    if (on_start_callback.call(upload_contexts[upload_num], file)===false) { //if start returns false, treat it as a cancellation
      setUploadState(upload_num, 4);
      return false;
    }

    if (getUploadState(upload_num) > 0) //if this.upload.cancel() was called inside the start function, don't start upload
      return false;

  setUploadState(upload_num, 1);

};

var on_progress = function(upload_num, progress){

    if (getUploadState(upload_num)==1)
      on_progress_callback.call(upload_contexts[upload_num], progress);

};

var on_success = function(upload_num, data){

    if (getUploadState(upload_num)==1)
    {
    setUploadState(upload_num, 2);
    on_success_callback.call(upload_contexts[upload_num], data);
    file_completed(upload_num, "success");
    }

};

var on_error = function(upload_num, error){

    if (getUploadState(upload_num)==1)
    {
    setUploadState(upload_num, 3);
    on_error_callback.call(upload_contexts[upload_num], error);
    file_completed(upload_num, "error");
    }

};

var on_cancel = function(upload_num){

  //the this.upload.cancel() function restricts when this can be called

  on_cancel_callback.call(upload_contexts[upload_num]);
  file_completed(upload_num, "cancel");

};

var on_complete = function(upload_num, status){

  on_complete_callback.call(upload_contexts[upload_num], status);

};

var on_finish = function(){

  on_finish_callback.call(instance_context);

    if (hidden_form!=null)
      hidden_form.remove();

};

/* End callback wrappers */



	/*
	 * Initialize instance and put uploads in the queue
	 */

	function create()
	{

	  if (typeof options=="object" && options!==null)
	  {

	    if (typeof options.forceIframe=="boolean")
	    {
	    forceIframe = options.forceIframe;
	    }

	    if (typeof options.init=="function")
	    {
	    on_init_callback = options.init;
	    }

	    if (typeof options.start=="function")
	    {
	    on_start_callback = options.start;
	    }

	    if (typeof options.progress=="function")
	    {
	    on_progress_callback = options.progress;
	    }

	    if (typeof options.success=="function")
	    {
	    on_success_callback = options.success;
	    }

	    if (typeof options.error=="function")
	    {
	    on_error_callback = options.error;
	    }

	    if (typeof options.cancel=="function")
	    {
	    on_cancel_callback = options.cancel;
	    }

	    if (typeof options.complete=="function")
	    {
	    on_complete_callback = options.complete;
	    }

	    if (typeof options.finish=="function")
	    {
	    on_finish_callback = options.finish;
	    }

	    if (typeof options.hashWorker=="string" && options.hashWorker!="")
	    {
	    hash_worker = options.hashWorker;
	    }

	    if (typeof options.hashComplete=="function")
	    {
	    on_hash_complete = options.hashComplete;
	    }

	    if (typeof options.data=="object" && options.data!==null)
	    {

	      for (var x in options.data) //copy each item in case options.data is actually an array
	      {
	      request_data[x] = options.data[x];
	      }

	    }

	    if (typeof options.limit=="number" && isInt(options.limit) && options.limit > 0)
	    {
	    limit = options.limit;
	    }

	    if (typeof options.maxFileSize=="number" && isInt(options.maxFileSize) && options.maxFileSize > 0)
	    {
	    max_file_size = options.maxFileSize;
	    }

	    if (typeof options.allowedExts=="object" && options.allowedExts!==null)
	    {

	      for (var x in options.allowedExts) //ensure allowed_exts stays an array
	      {
	      allowed_exts.push(options.allowedExts[x]);
	      }

	    }

	    if (typeof options.allowedTypes=="object" && options.allowedTypes!==null)
	    {

	      for (var x in options.allowedTypes) //ensure allowed_types stays an array
	      {
	      allowed_types.push(options.allowedTypes[x]);
	      }

	    }

	    if (typeof options.expect=="string" && options.expect!="")
	    {

	    var lower_expect = options.expect.toLowerCase();
	    var valid_expect_types = ["auto", "json", "xml", "html", "script", "text"]; //expect_type must be one of these

	      for (var x in valid_expect_types)
	      {

	        if (valid_expect_types[x]==lower_expect)
	        {
	        expect_type = lower_expect;
	        break;
	        }

	      }

	    }

	    if (typeof options.xhrFields=="object" && options.xhrFields!==null)
	    {

	      for (var x in options.xhrFields) //maintain as object
	      {
	      xhrFields[x] = options.xhrFields[x];
	      }

	    }

	  }

	  if (typeof DOM_file=="object" && DOM_file!==null && DOM_file instanceof jQuery)
	  {

	    if (DOM_file.length > 0)
	    {
	    DOM_file = DOM_file.get(0); //if DOM_file was passed in as a jquery object, extract its first DOM element and use it instead
	    }
	    else
	    {
	    return false; //if jquery object was empty, quit now
	    }

	  }

	  if (!forceIframe && window.File && window.FileReader && window.FileList && window.Blob) //check whether browser supports HTML5 File API
	  {

	    if (typeof options=="object" && options!==null && typeof options.files=="object" && options.files!==null)
	    {
	    files = options.files; //if options.files is defined along with DOM_file, it is the caller's responsibility to make sure they are the same
	    }
	    else if (typeof DOM_file=="object" && DOM_file!==null && typeof DOM_file.files=="object" && DOM_file.files!==null)
	    {
	    files = DOM_file.files; //fallback on DOM file input if no options.files are given
	    }

	  }

	  if ((typeof DOM_file!="object" || DOM_file===null) && files==null)
	  {
	  return false; //we've got nothing to work with, so just quit
	  }

	  //request_file_name will be based on (in order of preference) options.name, DOM_file.name, "file"

	  //if there is an attempt to upload multiple files as an array in one request, restrict it to one file per request, otherwise it will break consistency between ajax and iframe upload methods

	  if (typeof options=="object" && options!==null && typeof options.name=="string" && options.name!="")
	  {
	  request_file_name = options.name.replace(/\[\s*\]/g, '[0]');
	  }
	  else if (typeof DOM_file=="object" && DOM_file!==null && typeof DOM_file.name=="string" && DOM_file.name!="")
	  {
	  request_file_name = DOM_file.name.replace(/\[\s*\]/g, '[0]');
	  }

	var num_files = 0;

	  if (files!=null)
	  {

	    if (files.length > 0)
	    {

	      //the following conditions are necessary in order to do an AJAX upload (minus hashing), so don't start more than one upload if we're certain we'll fallback to the iframe method anyway

	      if (files.length > 1 && window.FormData && $.ajaxSettings.xhr().upload)
	      {

	        if (limit > 0 && files.length > limit) //apply limit if multiple files have been selected
	        {
	        num_files = limit;
	        }
	        else
	        {
	        num_files = files.length;
	        }

	      }
	      else
	      {
	      num_files = 1;
	      }

	    }

	  }
	  else
	  {

	    if (DOM_file.value!="")
	    {
	    num_files = 1;
	    }

	  }

	  if (num_files > 0)
	  {

	    if (typeof DOM_file=="object" && DOM_file!==null)
	    {

	    var $DOM_file = $(DOM_file);

	    hidden_form = $('<form>').hide().attr("enctype", "multipart/form-data").attr("method", "post").appendTo('body');

	    //move the original file input into the hidden form and create a clone of the original to replace it (clone doesn't retain value)
	    $DOM_file.after($DOM_file.clone(true).val("")).removeAttr("onchange").off().removeAttr("id").attr("name", request_file_name).appendTo(hidden_form);

	    }

	    for (var i = 0; i < num_files; i++)
	    {

	    (function(i){

	      //setting up contextual data...

	      //not accessible in callbacks directly, but provides data for certain functions that can be run in the callbacks
	      private_upload_data[i] = {
	      	state: 0, //state of upload in number form (0 = init, 1 = uploading, 2 = success, 3 = error, 4 = cancel)
	      	hashWorker: null, //Worker object from hashing
	        xhr: null, //jqXHR object from ajax upload
	        iframe: null //iframe id from iframe upload
	      };

	      //this object is accessible via "this" in each file-specific callback (for init and finish, this object is stacked in an array for each file)
	      upload_contexts[i] = {
	        upload: {
	          index: i,
	          state: "init", //textual form of "state" in private_upload_data
	          file: (files!=null) ? files[i] : { name: DOM_file.value.split(/(\\|\/)/g).pop() }, //ensure "name" always exists, regardless of HTML5 support
	          cancel: function(){

	              if (getUploadState(i)==0) //if upload hasn't started, don't call the callback, just change the state
	              {
	              setUploadState(i, 4);
	              }
	              else if (getUploadState(i)==1) //cancel if active and call the callback
	              {

	              setUploadState(i, 4);

	                if (private_upload_data[i].hashWorker!=null)
	                {
	                private_upload_data[i].hashWorker.terminate();
	                private_upload_data[i].hashWorker = null;
	                }

	                if (private_upload_data[i].xhr!=null)
	                {
	                private_upload_data[i].xhr.abort();
	                private_upload_data[i].xhr = null;
	                }

	                if (private_upload_data[i].iframe!=null)
	                {
	                $('iframe[name=simpleUpload_iframe_' + private_upload_data[i].iframe + ']').attr("src", "javascript:false;"); //for IE
	                simpleUpload.dequeueIframe(private_upload_data[i].iframe);
	                private_upload_data[i].iframe = null;
	                }

	              on_cancel(i);

	              }
	              else //return false if upload has already completed or been cancelled
	              {
	              return false;
	              }

	            return true; //cancel was a success

	          }
	        }
	      };

	    })(i);

	    }

	  var init_value = on_init(num_files);

	    if (init_value!==false)
	    {

	    //if the return value of on_init (init_value) is a number, limit the amount of uploads to that number (a value of 0, like false, will cancel all uploads)

	    var num_files_limit = num_files;

	      if (typeof init_value=="number" && isInt(init_value) && init_value >= 0 && init_value < num_files)
	      {

	      num_files_limit = init_value;

	        for (var z = num_files_limit; z < num_files; z++)
	        {
	        setUploadState(z, 4); //mark each remaining file after the new limit as cancelled
	        }

	      }

	    var remaining_uploads = []; //array of indexes of files to be uploaded from this instance

	      for (var j = 0; j < num_files_limit; j++)
	      {

	        if (on_start(j, upload_contexts[j].upload.file)!==false) //if false is returned, exclude this file from being uploaded
	          remaining_uploads[remaining_uploads.length] = j;

	      }

	      if (remaining_uploads.length > 0)
	      {

	      queued_files = remaining_uploads.length;

	      simpleUpload.queueUpload(remaining_uploads, function(upload_num){
	        validateFile(upload_num);
	      });

	      simpleUpload.uploadNext();

	      }
	      else
	      {
	      on_finish();
	      }

	    }
	    else //init returned false
	    {

	      for (var z in upload_contexts)
	      {
	      setUploadState(z, 4); //mark each file as cancelled
	      }

	    on_finish();

	    }

	  }

	}



	/*
	 * Run each file through the validation process
	 */

	function validateFile(upload_num)
	{

	  if (getUploadState(upload_num)!=1) //stop if upload has been cancelled
	    return;

	var file = null;

	  if (files!=null) //HTML5
	  {

	    if (files[upload_num]!=undefined && files[upload_num]!=null)
	    {
	    file = files[upload_num];
	    }
	    else //shouldn't happen, unless the files parameter passed in the beginning is not valid, or the passed-by-reference files object has been changed
	    {
	    on_error(upload_num, { name: "InternalError", message: "There was an error uploading the file" });
	    return;
	    }

	  }
	  else
	  {

	    if (DOM_file.value=="")
	    {
	    on_error(upload_num, { name: "InternalError", message: "There was an error uploading the file" });
	    return;
	    }

	  }

	//it's okay for file to be null, which signifies lack of HTML5 support

	//if certain information cannot be obtained because of a lack of support via javascript, these checks will return as valid by default, pending server-side checks after uploading

	  if (allowed_exts.length > 0 && !validateFileExtension(allowed_exts, file))
	  {
	  on_error(upload_num, { name: "InvalidFileExtensionError", message: "That file format is not allowed" });
	  return;
	  }

	  if (allowed_types.length > 0 && !validateFileMimeType(allowed_types, file))
	  {
	  on_error(upload_num, { name: "InvalidFileTypeError", message: "That file format is not allowed" });
	  return;
	  }

	  if (max_file_size > 0 && !validateFileSize(max_file_size, file))
	  {
	  on_error(upload_num, { name: "MaxFileSizeError", message: "That file is too big" });
	  return;
	  }

	//file passed validation checks

	  if (hash_worker!=null && on_hash_complete!=null) //if hash worker and hash complete function are present, attempt hashing...
	  {
	  hashFile(upload_num);
	  }
	  else //skip hashing and continue to upload file...
	  {
	  uploadFile(upload_num);
	  }

	}



	/*
	 * If a hash is desired, complete the hashing
	 */

	function hashFile(upload_num)
	{

	  if (files!=null) //HTML5
	  {

	    if (files[upload_num]!=undefined && files[upload_num]!=null)
	    {

	      if (window.Worker) //if the Web Workers API is supported (without it, hashing may lock up the browser)
	      {

	      var file = files[upload_num];

	        if (file.size!=undefined && file.size!=null && file.size!="" && isInt(file.size) && (file.slice || file.webkitSlice || file.mozSlice)) //check whether we've got the necessary HTML5 stuff
	        {

	          try {

	            var worker = new Worker(hash_worker);

	            worker.addEventListener('error', function(event){ //if anything goes wrong, just upload the file
	              worker.terminate();
	              private_upload_data[upload_num].hashWorker = null;
	              uploadFile(upload_num);
	            }, false);

	            worker.addEventListener('message', function(event){
	              if (event.data.result) {
	                var hash = event.data.result;
	                worker.terminate();
	                private_upload_data[upload_num].hashWorker = null;
	                checkHash(upload_num, hash); //hash was calculated successfully, now go check it
	              }
	            }, false);

	            var buffer_size, block, reader, blob, handle_hash_block, handle_load_block;

	            handle_load_block = function(event){
	              worker.postMessage({
	                'message' : event.target.result,
	                'block' : block
	              });
	            };

	            handle_hash_block = function(event){

	              if (block.end !== file.size)
	              {

	              block.start += buffer_size;
	              block.end += buffer_size;

	                if (block.end > file.size)
	                {
	                block.end = file.size;
	                }

	              reader = new FileReader();
	              reader.onload = handle_load_block;

	                if (file.slice) {
	                  blob = file.slice(block.start, block.end);
	                } else if (file.webkitSlice) {
	                  blob = file.webkitSlice(block.start, block.end);
	                } else if (file.mozSlice) {
	                  blob = file.mozSlice(block.start, block.end);
	                }

	              reader.readAsArrayBuffer(blob);

	              }

	            };

	            buffer_size = 64 * 16 * 1024;

	            block = {
	              'file_size' : file.size,
	              'start' : 0
	            };

	            block.end = buffer_size > file.size ? file.size : buffer_size;

	            worker.addEventListener('message', handle_hash_block, false);

	            reader = new FileReader();
	            reader.onload = handle_load_block;

	              if (file.slice) {
	                blob = file.slice(block.start, block.end);
	              } else if (file.webkitSlice) {
	                blob = file.webkitSlice(block.start, block.end);
	              } else if (file.mozSlice) {
	                blob = file.mozSlice(block.start, block.end);
	              }

	            reader.readAsArrayBuffer(blob);

	            private_upload_data[upload_num].hashWorker = worker; //store the worker to make it cancellable

	            return;

	          } catch(e) { //some unknown error occurred

	          }

	        } //else could not determine file size or could not use the File API's slice() method

	      } //else the Web Workers API is not supported

	    }

	  }

	uploadFile(upload_num);

	}



	/*
	 * Once a hash is calculated, send the hash along with some callbacks to the hashComplete() callback
	 */

	function checkHash(upload_num, hash)
	{

	  if (getUploadState(upload_num)!=1) //stop if upload has been cancelled
	    return;

	//because on_hash_complete is likely to run an asynchronous ajax call, pass callbacks to the function in order to take action when ready

	var callback_received = false; //only allow one callback to run once

	var success_callback = function(data){
	  if (getUploadState(upload_num)!=1) return false;
	  if (callback_received) return false;
	  callback_received = true;
	  on_progress(upload_num, 100);
	  on_success(upload_num, data);
	  return true;
	};

	var proceed_callback = function(){
	  if (getUploadState(upload_num)!=1) return false;
	  if (callback_received) return false;
	  callback_received = true;
	  uploadFile(upload_num);
	  return true;
	};

	var error_callback = function(error){
	  if (getUploadState(upload_num)!=1) return false;
	  if (callback_received) return false;
	  callback_received = true;
	  on_error(upload_num, { name: "HashError", message: error });
	  return true;
	};

	on_hash_complete.call(upload_contexts[upload_num], hash, { success: success_callback, proceed: proceed_callback, error: error_callback }); //IE has issues with "continue" as property name

	}



	/*
	 * Either after validation or a proceed() signal is received from the hash callback, continue to upload the file via AJAX
	 */

	function uploadFile(upload_num)
	{

	  if (getUploadState(upload_num)!=1) //stop if upload has been cancelled
	    return;

	  if (files!=null) //HTML5
	  {

	    if (files[upload_num]!=undefined && files[upload_num]!=null)
	    {

	      if (window.FormData)
	      {

	      var ajax_xhr = $.ajaxSettings.xhr();

	        if (ajax_xhr.upload) //check if upload property exists in XMLHttpRequest object
	        {

	        var file = files[upload_num];

	        var formData = new FormData();

	        objectToFormData(formData, request_data);

	        formData.append(request_file_name, file); //associate the file with options.name, the name of the DOM_file element, or "file" if one does not exist (in that order)

	        var ajax_settings = { url: ajax_url, data: formData, type: 'post', cache: false, xhrFields: xhrFields, beforeSend: function(jqXHR) {

	          private_upload_data[upload_num].xhr = jqXHR; //store the jqXHR object to make the upload cancellable

	        }, xhr: function() { //custom xhr

	          ajax_xhr.upload.addEventListener('progress', function(e) {

	            if (e.lengthComputable)
	            {
	            on_progress(upload_num, (e.loaded/e.total)*100);
	            }

	          }, false); // for handling the progress of the upload

	          return ajax_xhr;

	        }, error: function() {

	          private_upload_data[upload_num].xhr = null;

	          on_error(upload_num, { name: "RequestError", message: "Could not get response from server" });

	        }, success: function(data) {

	          private_upload_data[upload_num].xhr = null;

	          on_progress(upload_num, 100);
	          on_success(upload_num, data);

	        }, contentType: false, processData: false }; //options to tell JQuery not to process data or worry about content-type

	          //if expect_type is "auto", let the ajax function determine the type of output based on the mime-type of the response, otherwise force it

	          if (expect_type!="auto")
	          {
	          ajax_settings.dataType = expect_type;
	          }

	        $.ajax(ajax_settings); //execute ajax request

	        return;

	        }

	      }

	    }
	    else
	    {
	    on_error(upload_num, { name: "InternalError", message: "There was an error uploading the file" });
	    return;
	    }

	  }

	  if (typeof DOM_file=="object" && DOM_file!==null) //FALLBACK TO IFRAME IF BROWSER NOT HTML5 CAPABLE
	  {
	  uploadFileFallback(upload_num);
	  }
	  else //can't do AJAX file upload, and we weren't given a DOM_file to fall back on (can be caused by a drag-n-drop operation where "files" was given but DOM_file was not)
	  {
	  on_error(upload_num, { name: "UnsupportedError", message: "Your browser does not support this upload method" });
	  }

	}



	/*
	 * If the browser does not support AJAX file uploads, fall back to the iframe method
	 */

	function uploadFileFallback(upload_num)
	{

	  /*
	   * Limit uploads using the iframe method to 1 for the following reasons:
	   * 1. To keep it consistent with the one-file-per-request structure
	   * 2. To prevent confusingly long wait times on individual files because we must wait for all the files to be processed first
	   */

	  if (upload_num==0)
	  {

	  var iframe_id = simpleUpload.queueIframe({

	    origin: getOrigin(ajax_url), //origin of ajax_url, in order to verify potential cross-domain request via postMessage() is secure

	    expect: expect_type, //expected type of response

	    complete: function(data){ //on complete

	        if (getUploadState(upload_num)!=1) //stop if upload has been cancelled
	          return;

	      private_upload_data[upload_num].iframe = null;

	      simpleUpload.dequeueIframe(iframe_id);

	      on_progress(upload_num, 100);
	      on_success(upload_num, data);

	    },

	    error: function(error){ //on error (since iframes can't catch HTTP status codes, this only happens on parsing error)

	        if (getUploadState(upload_num)!=1) //stop if upload has been cancelled
	          return;

	      private_upload_data[upload_num].iframe = null;

	      simpleUpload.dequeueIframe(iframe_id);

	      on_error(upload_num, { name: "RequestError", message: error });

	    }

	  });

	  private_upload_data[upload_num].iframe = iframe_id; //store the iframe id to make the upload cancellable

	  //hook up hidden form with iframe and include request_data as hidden fields, then submit

	  var upload_data = objectToInput(request_data);

	  //add "_iframeUpload" parameter to ajax_url with id to iframe, and "_" parameter with current time in milliseconds to prevent caching
	  hidden_form.attr("action", ajax_url + ((ajax_url.lastIndexOf("?")==-1) ? "?" : "&") + "_iframeUpload=" + iframe_id + "&_=" + (new Date()).getTime()).attr("target", "simpleUpload_iframe_" + iframe_id).prepend(upload_data).submit();

	  }
	  else
	  {
	  on_error(upload_num, { name: "UnsupportedError", message: "Multiple file uploads not supported" }); //it is very unlikely this error will ever be returned, if not impossible
	  }

	}



	/*
	 * Convert an object to hidden input fields (must return as string to maintain order)
	 */

	function objectToInput(obj, parent_node)
	{

	  if (parent_node===undefined || parent_node===null || parent_node==="")
	  {
	  parent_node = null;
	  }

	var html = "";

	  for (var key in obj)
	  {

	    if (obj[key]===undefined || obj[key]===null)
	    {
	    html += $('<div>').append($('<input type="hidden">').attr("name", (parent_node==null) ? key + "" : parent_node + "[" + key + "]").val("")).html();
	    }
	    else if (typeof obj[key]=="object")
	    {
	    html += objectToInput(obj[key], (parent_node==null) ? key + "" : parent_node + "[" + key + "]");
	    }
	    else if (typeof obj[key]=="boolean")
	    {
	    html += $('<div>').append($('<input type="hidden">').attr("name", (parent_node==null) ? key + "" : parent_node + "[" + key + "]").val((obj[key]) ? "true" : "false")).html();
	    }
	    else if (typeof obj[key]=="number")
	    {
	    html += $('<div>').append($('<input type="hidden">').attr("name", (parent_node==null) ? key + "" : parent_node + "[" + key + "]").val(obj[key] + "")).html();
	    }
	    else if (typeof obj[key]=="string")
	    {
	    html += $('<div>').append($('<input type="hidden">').attr("name", (parent_node==null) ? key + "" : parent_node + "[" + key + "]").val(obj[key])).html();
	    }

	  }

	return html;

	}



	/*
	 * Append each key/value pair in an object to a formData object
	 */

	function objectToFormData(formData, obj, parent_node)
	{

	  if (parent_node===undefined || parent_node===null || parent_node==="")
	  {
	  parent_node = null;
	  }

	  for (var key in obj)
	  {

	    if (obj[key]===undefined || obj[key]===null)
	    {
	    formData.append((parent_node==null) ? key + "" : parent_node + "[" + key + "]", "");
	    }
	    else if (typeof obj[key]=="object")
	    {
	    objectToFormData(formData, obj[key], (parent_node==null) ? key + "" : parent_node + "[" + key + "]");
	    }
	    else if (typeof obj[key]=="boolean")
	    {
	    formData.append((parent_node==null) ? key + "" : parent_node + "[" + key + "]", (obj[key]) ? "true" : "false");
	    }
	    else if (typeof obj[key]=="number")
	    {
	    formData.append((parent_node==null) ? key + "" : parent_node + "[" + key + "]", obj[key] + "");
	    }
	    else if (typeof obj[key]=="string")
	    {
	    formData.append((parent_node==null) ? key + "" : parent_node + "[" + key + "]", obj[key]);
	    }

	  }

	}



	/*
	 * Get/set state in number form and text form in private_upload_data and upload_contexts
	 */

	function getUploadState(upload_num)
	{
	return private_upload_data[upload_num].state;
	}

	function setUploadState(upload_num, state)
	{

	var textState = "";

	  if (state==0)
	    textState = "init";
	  else if (state==1)
	    textState = "uploading";
	  else if (state==2)
	    textState = "success";
	  else if (state==3)
	    textState = "error";
	  else if (state==4)
	    textState = "cancel";
	  else
	    return false;

	private_upload_data[upload_num].state = state; //for internal use

	upload_contexts[upload_num].upload.state = textState; //for public use

	}



	/*
	 * Get the extension of a filename
	 */

	function getFileExtension(filename)
	{
	var filename_dot_pos = filename.lastIndexOf('.');
	return (filename_dot_pos!=-1) ? filename.substr(filename_dot_pos + 1) : "";
	}



	/*
	 * Validate file extension and return true if valid (if not sure, assume it's valid)
	 */

	function validateFileExtension(valid_exts, file)
	{

	  if (file!=undefined && file!=null) //if file is specified (would require HTML5)
	  {

	  var file_name = file.name;

	    if (file_name!=undefined && file_name!=null && file_name!="") //the browser could return an empty value, even if it's a legit upload
	    {

	    var file_ext = getFileExtension(file_name).toLowerCase();

	      if (file_ext!="") //extension exists
	      {

	      var valid_ext = false;

	        for (var i in valid_exts)
	        {

	          if (valid_exts[i].toLowerCase()==file_ext)
	          {
	          valid_ext = true;
	          break;
	          }

	        }

	        if (valid_ext)
	        {
	        return true;
	        }
	        else
	        {
	        return false;
	        }

	      }
	      else
	      {
	      return false;
	      }

	    }

	  }

	//if the HTML5 check fails, fallback to the old-school way (won't support multiple file uploads)

	  if (typeof DOM_file=="object" && DOM_file!==null)
	  {

	  var DOM_file_name = DOM_file.value;

	    if (DOM_file_name!="")
	    {

	    var file_ext = getFileExtension(DOM_file_name).toLowerCase();

	      if (file_ext!="")
	      {

	      var valid_ext = false;

	        for (var i in valid_exts)
	        {

	          if (valid_exts[i].toLowerCase()==file_ext)
	          {
	          valid_ext = true;
	          break;
	          }

	        }

	        if (valid_ext)
	        {
	        return true;
	        }

	      }

	    }

	  }
	  else
	  {
	  return true; //we can't check DOM_file or file, so assume it's valid (could occur during a drag-n-drop operation where we are only given the file, but perhaps the browser won't give us a filename)
	  }

	return false;

	}



	/*
	 * Validate file mime-type and return true if valid (if not sure, assume it's valid)
	 */

	function validateFileMimeType(valid_mime_types, file)
	{

	  if (file!=undefined && file!=null) //if file is specified (would require HTML5)
	  {

	  var file_mime_type = file.type;

	    if (file_mime_type!=undefined && file_mime_type!=null && file_mime_type!="") //the browser could return an empty value, even if it's a legit upload
	    {

	    file_mime_type = file_mime_type.toLowerCase();

	    var valid_mime_type = false;

	      for (var i in valid_mime_types)
	      {

	        if (valid_mime_types[i].toLowerCase()==file_mime_type)
	        {
	        valid_mime_type = true;
	        break;
	        }

	      }

	      if (valid_mime_type)
	      {
	      return true;
	      }
	      else
	      {
	      return false;
	      }

	    }

	  }

	return true; //we can only check the mime-type if the browser has the HTML5 File API, so if that fails, it may be a valid upload for all we know

	}



	/*
	 * Validate file size in bytes and return true if valid (if not sure, assume it's valid)
	 */

	function validateFileSize(max_size, file)
	{

	  if (file!=undefined && file!=null) //if file is specified (would require HTML5)
	  {

	  var file_size = file.size;

	    if (file_size!=undefined && file_size!=null && file_size!="" && isInt(file_size)) //the browser could return an empty value, even if it's a legit upload
	    {

	      if (file_size <= max_size) //must be less than or equal to max_size (in bytes)
	      {
	      return true;
	      }
	      else
	      {
	      return false;
	      }

	    }

	  }

	return true; //we can only check the file size if the browser has the HTML5 File API, so if that fails, it may be a valid upload for all we know

	}



	/*
	 * Input filtering function
	 */

	function isInt(num)
	{

	  if (!isNaN(num))
	  {

	    if ((parseInt(num)+"")==num)
	    {
	    return true;
	    }

	  }

	return false;

	}



	/*
	 * Get the "origin" of a URL (e.g. http://example.org:8080). Used for verifying the identity of messages received via postMessage().
	 */

	function getOrigin(url)
	{

	var a = document.createElement('a');
	a.href = url;

	var host = a.host;
	var protocol = a.protocol;

	  if (host=="")
	    host = window.location.host;

	  if (protocol=="" || protocol==":") //for protocol-relative URLs, sometimes IE will return ":"
	    protocol = window.location.protocol;

	return protocol.replace(/\:$/, '') + "://" + host; //normalize colon in protocol in case of browser inconsistencies

	}



create();



}



/*
 * Global variables and functions that need to be maintained throughout upload instances
 */

simpleUpload.maxUploads = 10; //maximum amount of simultaneous uploads
simpleUpload.activeUploads = 0; //keep track of active uploads

simpleUpload.uploads = []; //multi-dimensional array containing the id's and callbacks of all remaining file uploads

simpleUpload.iframes = {}; //"associative array" where the iframe id is the key
simpleUpload.iframeCount = 0; //more efficient way to keep track of the number of iframes

/*
 * When an upload is started, it is first put into a global queue to ensure the browser isn't under too heavy a load.
 * These functions are used to add and subtract uploads to/from the queue.
 */

simpleUpload.queueUpload = function(remaining_uploads, upload_callback){ //queue upload instance (an instance is a set of files to upload after each file selection)

  simpleUpload.uploads[simpleUpload.uploads.length] = { uploads: remaining_uploads, callback: upload_callback };

};

simpleUpload.uploadNext = function(){

    if (simpleUpload.uploads.length > 0 && simpleUpload.activeUploads < simpleUpload.maxUploads) //there are remaining uploads and we haven't hit the limit of max simultaneous uploads yet
    {

    var upload_instance = simpleUpload.uploads[0];

    var upload_callback = upload_instance.callback;
    var upload_num = upload_instance.uploads.splice(0, 1)[0];

      if (upload_instance.uploads.length==0)
      {
      simpleUpload.uploads.splice(0, 1);
      }

    simpleUpload.activeUploads++;
    upload_callback(upload_num);

    simpleUpload.uploadNext();

    }

};

/*
 * Used to track iframes during an upload
 */

simpleUpload.queueIframe = function(opts){

  var id = 0;

    while (id==0 || id in simpleUpload.iframes)
    {
    id = Math.floor((Math.random()*999999999)+1); //generate unique id for iframe
    }

  simpleUpload.iframes[id] = opts; //an object containing data and callbacks that refer back to the originating upload instance
  simpleUpload.iframeCount++;

  $('body').append('<iframe name="simpleUpload_iframe_' + id + '" style="display: none;"></iframe>');

  return id;

};

simpleUpload.dequeueIframe = function(id){

    if (id in simpleUpload.iframes)
    {

    $('iframe[name=simpleUpload_iframe_' + id + ']').remove(); //remove iframe from the DOM

    delete simpleUpload.iframes[id];
    simpleUpload.iframeCount--;

    }

};

/*
 * Negotiate the correct data type and return the data in the proper format
 *
 * expected_type: as declared by the upload instance's "expect" parameter
 * declared_type: the type defined in the iframe during callback
 * data: data as it was passed in the callback, may be a string, object, or object encoded as a string
 */

simpleUpload.convertDataType = function(expected_type, declared_type, data){

  var type = "auto"; //ultimate type to return data as

    if (expected_type=="auto") //if expected type is auto, base the type on the declared type
    {

      if (typeof declared_type=="string" && declared_type!="")
      {

      var lower_type = declared_type.toLowerCase();
      var valid_types = ["json", "xml", "html", "script", "text"];

        for (var x in valid_types)
        {

          if (valid_types[x]==lower_type)
          {
          type = lower_type; //only set if value is one of the types above
          break;
          }

        }

      }

    }
    else //force the type to be the expected type
    {
    type = expected_type;
    }

    /*
     * Attempt to keep data conversions similar to that of jQuery's $.ajax() function to stay consistent
     * See "dataType" setting: http://api.jquery.com/jquery.ajax/
     */

    if (type=="auto") //type could not be determined, so pass data back as object if it is an object, or string otherwise
    {

    // Output: string, object, null

      if (typeof data=="undefined")
      {
      return ""; //if data was not set, return an empty string
      }

      if (typeof data=="object")
      {
      return data; //if object, return as object (allow null)
      }

    return String(data); //if anything else, convert it to a string and return the string value

    }
    else if (type=="json")
    {

    // Output: object, null

      if (typeof data=="undefined" || data===null)
      {
      return null;
      }

      if (typeof data=="object")
      {
      return data; //if already an object, pass it right through
      }

      if (typeof data=="string")
      {

        try {

          return $.parseJSON(data); //JSON is valid, return object or null

        } catch(e) {

          return false; //JSON not valid

        }

      }

    return false; //data could not possibly be a valid JSON object or string

    }
    else if (type=="xml")
    {

    // Output: object (XMLDoc), null

      if (typeof data=="undefined" || data===null)
      {
      return null;
      }

      if (typeof data=="string")
      {

        try {

          return $.parseXML(data); //XML is valid, return object (native XMLDocument object) or null

        } catch(e) {

          return false; //XML is not valid

        }

      }

    return false; //data is not a string containing valid XML

    }
    else if (type=="script")
    {

    // Output: string

      if (typeof data=="undefined")
      {
      return "";
      }

      if (typeof data=="string")
      {

        try {

          $.globalEval(data); //execute script in the global scope

          return data; //return script as string

        } catch(e) {

          return false; //there was an error while executing the script with $.globalEval() - the script still may have run partially, but this is consistent behavior with $.ajax()

        }

      }

    return false; //data is not a string containing script to execute

    }
    else //if type is html or text, return as plain text...
    {

    // Output: string

      if (typeof data=="undefined")
      {
      return "";
      }

    return String(data); //convert data to string, regardless of data type

    }

};

/*
 * Callbacks to pass data back from an iframe, with the first applying to same-domain exchanges and the second to cross-domain exchanges using postMessage()
 */

simpleUpload.iframeCallback = function(data){

    if (typeof data=="object" && data!==null)
    {

    var id = data.id;

      if (id in simpleUpload.iframes)
      {

      var converted_data = simpleUpload.convertDataType(simpleUpload.iframes[id].expect, data.type, data.data);

        if (converted_data!==false)
        {
        simpleUpload.iframes[id].complete(converted_data);
        }
        else
        {
        simpleUpload.iframes[id].error("Could not get response from server");
        }

      }

    }

};

simpleUpload.postMessageCallback = function(e){

    try {

      var key = e.message ? "message" : "data";
      var data = e[key];

        if (typeof data=="string" && data!="") //data was passed as string
        {

        data = $.parseJSON(data); //convert JSON string to object (throws error on malformed JSON for jQuery >= 1.9, can return null if data is empty string, null, or undefined for older versions of jQuery)

          if (typeof data=="object" && data!==null) //data is now an object
          {

            //since window.addEventListener casts a large net for all messages, make sure this one is intended for us...

            if (typeof data.namespace=="string" && data.namespace=="simpleUpload")
            {

            //from now on, we can assume the message was meant for us, but NOT that it was delivered from a trusted source

            var id = data.id;

              if (id in simpleUpload.iframes) //id is valid
              {

                if (e.origin===simpleUpload.iframes[id].origin)
                {

                //origin of postMessage() is consistent with the origin of the URL to which the request was made, now we can trust the source

                //now determine the correct type of output and pass our data...

                var converted_data = simpleUpload.convertDataType(simpleUpload.iframes[id].expect, data.type, data.data);

                  if (converted_data!==false)
                  {
                  simpleUpload.iframes[id].complete(converted_data);
                  }
                  else
                  {
                  simpleUpload.iframes[id].error("Could not get response from server");
                  }

                }

              }

            }

          }

        }

    } catch(e) {

      //an error was thrown, could be the JSON data was unparsable

    }

};



// Listen for messages arriving over iframe using postMessage()

if (window.addEventListener) window.addEventListener("message", simpleUpload.postMessageCallback, false);
else window.attachEvent("onmessage", simpleUpload.postMessageCallback);



/*
 * jQuery plugin for simpleUpload
 */

(function (factory) {

  if (typeof define==="function" && define.amd) {
    // AMD. Register as an anonymous module.
    define(["jquery"], factory);
  } else if (typeof exports==="object") {
    // Node/CommonJS
    module.exports = factory(require("jquery"));
  } else {
    // Browser globals
    factory(jQuery);
  }

}(function ($) {

  //the main call

  $.fn.simpleUpload = function(url, opts){

    //if calling with $.fn.simpleUpload() and the "files" option is present, go ahead and pass it along...

  	if ($(this).length==0) {
  	  if (typeof opts=="object" && opts!==null && typeof opts.files=="object" && opts.files!==null) {
  	    new simpleUpload(url, null, opts);
  	    return this;
  	  }
  	}

    //likely being used in a chain

    return this.each(function(){
      new simpleUpload(url, this, opts);
    });

  };

  //allow getting/setting the simpleUpload.maxUploads variable

  $.fn.simpleUpload.maxSimultaneousUploads = function(num){

    if (typeof num==="undefined") {
      return simpleUpload.maxUploads;
    } else if (typeof num==="number" && num > 0) {
      simpleUpload.maxUploads = num;
      return this;
    }

  };

}));