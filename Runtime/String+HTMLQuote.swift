/* HTML quoting support for Swiftemplate runtime
 * https://github.com/andrewcb/swiftemplate/
 */

extension String {
    /** Escape all the HTML special characters (i.e., </>) in the string. */
    var HTMLQuote: String {
        var result: String = ""

        for ch in self.characters {
            switch(ch) {
                case "<": result.appendContentsOf("&lt;")
                case ">": result.appendContentsOf("&gt;")
                default: result.append(ch)
            }
        }
        return result
    }
}
