/* https://gist.githubusercontent.com/CarsonSlovoka/bf7cd5a172c24e89fbe31915776b73e5/raw/e3dfb7a6b3211d80e2e9e9c77b02393c7b015964/create-toc.html */

class TOC {
  /**
   * @param {[HTMLHeadingElement]} headingSet
   * */
  static parse(headingSet) {
    const tocData = []
    let curLevel = 0
    let previousTOCitem = undefined

    headingSet.forEach(heading => {
      const hLevel = heading.outerHTML.match(/<h([\d]).*>/)[1]
      const titleText = heading.innerText

      // console.log(hLevel)

      switch (hLevel >= curLevel) {
      case true:
        // console.log(titleText + " INC")
        if (previousTOCitem === undefined) {
          previousTOCitem = new TOCitem(titleText, hLevel)
          tocData.push(previousTOCitem)
        } else {
          const currentTOCitem = new TOCitem(titleText, hLevel)
          // The problematic one isn't here
          // console.log(titleText + " " + currentTOCitem.level + " " + previousTOCitem.level)

          const TOCparent = currentTOCitem.level > previousTOCitem.level ? previousTOCitem : previousTOCitem.TOCparent

          if (TOCparent) {
            currentTOCitem.TOCparent = TOCparent
            TOCparent.children.push(currentTOCitem)
            previousTOCitem = currentTOCitem
          } {
            // previousTOCitem = new TOCitem(titleText, hLevel)
            // tocData.push(previousTOCitem)
            // console.log(titleText + " NO PARENT")
          }
        }
        break
      case false:
        // console.log(titleText)
        // We need to find the appropriate TOCparent node from the previousTOCitem - This algorithm is problematic
        const currentTOCitem = new TOCitem(titleText, hLevel)
        while (1) {
          // console.log("previousTOCitem.level: " + previousTOCitem.level + "currentTOCitem.level: " + currentTOCitem.level)

          if (previousTOCitem.level < currentTOCitem.level) {
            previousTOCitem.children.push(currentTOCitem)
            previousTOCitem = currentTOCitem
            break
          }
          previousTOCitem = previousTOCitem.TOCparent

          if (previousTOCitem === undefined) {
            tocData.push(currentTOCitem)
            previousTOCitem = currentTOCitem
            break
          }
        }
        break
      }

      curLevel = hLevel

      if (heading.id === "") {
        heading.id = titleText.replace(/ /g, "-").toLowerCase()
      }
      previousTOCitem.id = heading.id
    })

    return tocData
  }

  /**
   * @param {[TOCitem]} tocData
   * @return {string}
   * */
  static build(tocData) {
    let result = "<ol>"
    tocData.forEach(toc => {
      result += `<li><a href=#${toc.id}>${toc.text}</a></li>`
      if (toc.children.length) {
        result += `${TOC.build(toc.children)}`
      }
    })
    return result + "</ol>"
  }
}

/**
 * @param {string} text
 * @param {int} level
 * @param {TOCitem} TOCparent
 * */
function TOCitem(text, level, TOCparent = undefined) {
  this.text = text
  this.level = level
  this.id = undefined
  this.TOCparent = TOCparent
  this.children = []
}

window.onload = () => {

  const headingSet = document.querySelectorAll("h1, h2, h3, h4, h5, h6") // You can also select only the titles you are interested in.
  const tocData = TOC.parse(headingSet)
  
  console.log(tocData)

  const tocHTMLContent = TOC.build(tocData)
  const frag = document.createRange().createContextualFragment(`<fieldset class="fixed-top"><legend>Table of Contents</legend>${tocHTMLContent}</fieldset>`)
  document.querySelector(`body`).insertBefore(frag, document.querySelector(`body`).firstChild)
}
