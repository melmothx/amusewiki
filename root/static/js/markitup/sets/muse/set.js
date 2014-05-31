// -------------------------------------------------------------------
// markItUp!
// -------------------------------------------------------------------
// Copyright (C) 2008 Jay Salvat
// http://markitup.jaysalvat.com/

mySettings = {
	previewParserPath:	'',
	onShiftEnter:		{keepDefault:false, openWith:'\n\n'},
	markupSet: [
	    {name:'Heading 1 (Part, for larger books only', 
	     key:'1', placeHolder:'Your part here...',
	     openWith:'\n* '},
	    {name:'Heading 2 (Chapter, only for chapter divisions in books)',
	     key:'2',
	     placeHolder:'Your chapter here...',
	     openWith:'\n** ' },
	    {name:'Heading 3 (generic sectioning, good for articles', key:'3', openWith:'\n*** ', placeHolder:'Your section here...' },
	    {name:'Heading 4', key:'4', openWith:'\n**** ', placeHolder:'Your subsection here...' },
	    {name:'Heading 5', key:'5', openWith:'\n***** ', placeHolder:'Your sub-sub-section (description heading) here...' },
	    {name:'Italic', key:'I', openWith:' *', closeWith:'* '},
	    {name:'Bold',   key:'B', openWith:' **', closeWith:'** '},
	    {name:'Bulleted List', openWith:'\n - ' },
	    {name:'Numeric List', openWith:'\n 1. ' },
	    {name:'Picture', key:'P', replaceWith:'[[[![Image url (see the gallery)]!]][[![description]!]]]' },
	    {name:'Link', key:'L', replaceWith:'[[[![Url:!:http://]!]][[![Display url as:]!]]]' },
	    {name:'Quotes', openWith:'  '},
	    {name:'Code Block / Code', multiline:true, openBlockWith:'\n<example>\n', closeBlockWith:'\n</example>\n'},
	]
}
