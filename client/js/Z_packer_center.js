// http://packery.metafizzy.co/packery.pkgd.js added as external resource

// overwrite Packery methods
function bla() {
var __resetLayout = Packery.prototype._resetLayout;
Packery.prototype._resetLayout = function() {
    __resetLayout.call( this );
    // reset packer
    var parentSize = getSize( this.element.parentNode );
    var columnWidth = this.columnWidth + this.gutter;
    this.fitWidth = Math.floor( ( parentSize.innerWidth + this.gutter ) / columnWidth ) * columnWidth;
    this.packer.width = this.fitWidth;
    this.packer.height = Number.POSITIVE_INFINITY;
    this.packer.reset();
};


Packery.prototype._getContainerSize = function() {
    // remove empty space from fit width
    var emptyWidth = 0;
    for ( var i=0, len = this.packer.spaces.length; i < len; i++ ) {
        var space = this.packer.spaces[i];
        if ( space.y === 0 ) {
            emptyWidth += space.width;
        }
    }

    return {
        width: this.fitWidth - emptyWidth - this.gutter,
        height: this.maxY - this.gutter
    };
};

// always resize
Packery.prototype.resize = function() {
    this.layout();
};



};

//Meteor.startup(function() {bla();})