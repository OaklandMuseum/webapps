import html
import toolbox.cswaConstants as cswaConstants
import toolbox.cswaDB as cswaDB

from toolbox.cswaConstants import OMCADATA
from toolbox.cswaConstants import getDropdown, ipAuditValues


def formatRow(result, form, config):
    hostname = config.get('connect', 'hostname')
    institution = config.get('info', 'institution')
    port = ''
    protocol = 'http'
    rr = result['data']
    rr = [x if x != None else '' for x in rr]

    try:
        csid = rr[8]
    except:
        csid = 'user'
    link = protocol + '://' + hostname + port + '/cspace/omca/record/collectionobject/%s' % csid

    # the link to acquisitions is for PAHMA...
    try:
        link2 = protocol + '://' + hostname + port + '/cspace/omca/record/acquisition/%s' % rr[24]
    except:
        link2 = ''

    try:
        csid = rr[0]
    except:
        csid = 'user'
    link3 = protocol + '://' + hostname + port + '/cspace/omca/record/collectionobject/%s' % csid


    if result['rowtype'] == 'subheader':
        return """<tr><td colspan="7" class="subheader">%s</td></tr>""" % result['data'][0]
    elif result['rowtype'] == 'location':
        return '''<tr><td class="objno"><a href="#" onclick="formSubmit('%s')">%s</a> <span style="color:red;">%s</span></td><td/></tr>''' % (
            result['data'][0], result['data'][0], '')
    elif result['rowtype'] == 'select':
        rr = result['data']
        boxType = result['boxtype']
        return '''<li class="xspan"><input type="checkbox" name="%s.%s" value="%s" checked> <a href="#" onclick="formSubmit('%s')">%s</a></li>''' % (
            (boxType,) + (rr[0],) * 4)
    elif result['rowtype'] == 'inventory':
        return """<tr><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td class="rdo" ><input type="radio" id="sel-move" name="r.%s" value="found|%s|%s|%s|%s|%s" checked></td><td class="rdo" ><input type="radio" id="sel-nomove" name="r.%s" value="not found|%s|%s|%s|%s|%s"/></td><td class="zcell"><input class="xspan" type="text" size="65" name="n.%s"></td></tr>""" % (
                link, rr[3], rr[5], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14], rr[3], rr[8], rr[7], rr[6],
                rr[3], rr[14], rr[3])
    elif result['rowtype'] == 'powermove':
        return """<tr><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td class="rdo" ><input type="radio" id="sel-move" name="r.%s" value="move|%s|%s|%s|%s|%s"></td><td class="rdo" ><input type="radio" id="sel-nomove" name="r.%s" value="do not move|%s|%s|%s|%s|%s" checked/></td><td class="zcell"><input class="xspan" type="text" size="65" name="n.%s"></td></tr>""" % (
            link, rr[3], rr[5], rr[3],
            rr[8], rr[7], rr[6], rr[3], rr[14], rr[3],
            rr[8], rr[7], rr[6], rr[3], rr[14], rr[3])
    elif result['rowtype'] == 'moveobject':
        # 0 storageLocation | 1 objname | 2 objnum | 6 locrefname | 8 csid
        return """<tr><td class="rdo" ><input type="checkbox" name="r.%s" value="moved|%s|%s|%s|%s|%s" checked></td><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td class="zcell">%s</td><td class="zcell">%s</td></tr>""" % (
            rr[2], rr[8], rr[6], rr[1], rr[2], rr[1], link, rr[2], rr[1], '', rr[0])
            #rr[3], rr[8], rr[1], '', rr[3], rr[13], link, rr[3], rr[5], rr[4], rr[0])
    elif result['rowtype'] == 'keyinfo' or result['rowtype'] == 'objinfo':
        link2 = ''
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objname 4 | objcount 5| fieldcollectionplace 6 | culturalgroup 7 | objcsid 8 | ethnographicfilecode 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return formatInfoReviewRowOMCA(form, link, rr, link2)
    elif result['rowtype'] == 'packinglist':
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objname 4 | objcount 5| fieldcollectionplace 6 | culturalgroup 7 | objcsid 8 | ethnographicfilecode 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname" name="onm.%s">%s</td>
<td class="ncell" name="dh.%s">%s</td>
<td class="ncell" name="op.%s">%s</td>
<td class="ncell" name="ad.%s">%s</td>
</tr>""" % (link, rr[2], rr[0], rr[1], rr[0], rr[10], rr[0], rr[12], rr[0], rr[9])


def formatInfoReviewRowOMCA(form, link, rr, link2):
    fieldSet = form.get("fieldset")

    # omca labels
    for f in OMCADATA.keys():
        if fieldSet == f:
            rows = """<tr>
    <td class="objno"><a target="cspace" href="%s">%s</a>
    <input type="hidden" name="oox.%s" value="%s">
    <input type="hidden" name="csid.%s" value="%s">
    </td>""" % (link, rr[2], rr[8], rr[2], rr[8], rr[8])

            for x in OMCADATA[f]:
                # print x
                if 'objnum' == x[1]:
                    continue
                if 'ipAudit' == x[1]:
                    rows += '<td class="zcell">' + getDropdown(x[2], rr[8], ipAuditValues(), rr[18]) + '</td>'
                elif 'doNotPublishOnWeb' == x[1]:
                    rows += '<td class="zcell">' + getDropdown(x[2], rr[8],
                                                               [('Do not publish', 'true'), ('Publish', 'false')],
                                                               rr[16]) + '</td>'
                    # sys.stderr.write('dnp: %s\n' % (rr[16]))
                else:
                    rows += """<td class="zcell"><input class="xspan" type="text" name="%s.%s" value="%s"></td>""" % (
                    x[2], rr[8], html.escape(rr[x[3]], True))
            return rows

    if fieldSet == 'namedesc':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname">
<input class="objname" type="text" name="onm.%s" value="%s">
</td>
<td width="0"></td>
<td class="zcell">
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<textarea cols="78" rows="1" name="bdx.%s">%s</textarea></td>
</tr>""" % (link, html.escape(rr[3], True), rr[8], html.escape(rr[4], True), rr[8], html.escape(rr[3], True), rr[8], rr[8],
            rr[8], html.escape(rr[15], True))


def formatInfoReviewRow(form, link, rr, link2, link3, config):
    hostname = config.get('connect', 'hostname')
    institution = config.get('info', 'institution')
    fieldSet = form.get("fieldset")

    # omca labels
    for f in OMCADATA.keys():
        if fieldSet == f:
            rows = """<tr>
    <td class="objno"><a target="cspace" href="%s">%s</a>
    <input type="hidden" name="oox.%s" value="%s">
    <input type="hidden" name="csid.%s" value="%s">
    </td>""" % (link, rr[2], rr[8], rr[2], rr[8], rr[8])

            for x in OMCADATA[f]:
                # print x
                if 'objnum' == x[1]:
                    continue
                if 'ipAudit' == x[1]:
                    rows += '<td class="zcell">' + getDropdown(x[2], rr[8], ipAuditValues(), rr[18]) + '</td>'
                elif 'doNotPublishOnWeb' == x[1]:
                    rows += '<td class="zcell">' + getDropdown(x[2], rr[8],
                                                               [('Do not publish', 'true'), ('Publish', 'false')],
                                                               rr[16]) + '</td>'
                    # sys.stderr.write('dnp: %s\n' % (rr[16]))
                else:
                    rows += """<td class="zcell"><input class="xspan" type="text" name="%s.%s" value="%s"></td>""" % (
                    x[2], rr[8], html.escape(rr[x[3]], True))
            return rows

    if fieldSet == 'namedesc':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<td class="objname"><input class="objname" type="text" name="onm.%s" value="%s"></td>
<td width="0"></td>
<td class="zcell">
<textarea cols="78" rows="5" name="bdx.%s">%s</textarea></td>
</tr>""" % (link, html.escape(rr[3], True),
            rr[8], html.escape(rr[3], True),
            rr[8], rr[8],
            rr[8], html.escape(rr[4], True),
            rr[8], html.escape(rr[15], True))
    elif fieldSet == 'registration':
        altnumtypes, selected = cswaConstants.getAltNumTypes(form, rr[8], rr[19])
        objstatuses, selected = cswaConstants.getObjectStatuses(form, rr[8], rr[37])
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname"><input class="objname" type="text" name="onm.%s" value="%s"></td>
<td class="zcell">
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<input class="xspan" type="text" size="13" name="anm.%s" value="%s"></td>
<td class="zcell">%s</td>
<td class="zcell"><input class="xspan" type="text" size="40" name="cl.%s" value="%s"></td>
<td class="zcell">%s</td>
<td class="zcell"><span style="font-size:8">%s</span></td>
<td class="zcell"><a target="cspace" href="%s">%s</a></td>
</tr>""" % (link, html.escape(rr[3], True),
            rr[8], html.escape(rr[4], True),
            rr[8], html.escape(rr[3], True),
            rr[8], rr[8],
            rr[8], html.escape(rr[18], True),
            altnumtypes,
            rr[8], html.escape(rr[16], True),
            objstatuses,
            html.escape(rr[17], True),
            link2, html.escape(rr[21], True))
    elif fieldSet == 'keyinfo':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname"><input class="objname" type="text" name="onm.%s" value="%s"></td>
<td class="veryshortinput"><input class="veryshortinput" type="text" name="ocn.%s" value="%s"></td>
<td class="zcell">
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<input class="xspan" type="text" size="40" name="cp.%s" value="%s"></td>
<td class="zcell"><input class="xspan" type="text" size="40" name="cg.%s" value="%s"></td>
<td class="zcell"><input class="xspan" type="text" size="40" name="fc.%s" value="%s"></td>
</tr>""" % (link, html.escape(rr[3], True), rr[8], html.escape(rr[4], True), rr[8], rr[5], rr[8], html.escape(rr[3], True),
            rr[8], rr[8], rr[8], html.escape(rr[6], True), rr[8], html.escape(rr[7], True), rr[8],
            html.escape(rr[9], True))
    elif fieldSet == 'hsrinfo':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname"><input class="objname" type="text" name="onm.%s" value="%s"></td>
<td class="veryshortinput"><input class="veryshortinput" type="text" name="ocn.%s" value="%s"></td>
<td class="zcell">
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<input class="xspan" type="text" size="20" name="ctn.%s" value="%s"></td>
<td class="zcell"><input class="xspan" type="text" size="40" name="cp.%s" value="%s"></td>
<td class="zcell"><textarea cols="78" rows="5" name="bdx.%s">%s</textarea></td>
</tr>""" % (link, html.escape(rr[3], True), rr[8], html.escape(rr[4], True),
            rr[8], rr[5],
            rr[8], html.escape(rr[3], True),
            rr[8], rr[8], rr[8], html.escape(rr[25], True),
            rr[8], html.escape(rr[6], True), rr[8],
            html.escape(rr[15], True))
    elif fieldSet == 'objtypecm':
        objtypes, selected = cswaConstants.getObjType(form, rr[8], rr[26])
        collmans, selected = cswaConstants.getCollMan(form, rr[8], rr[27])
        legacydepartments, selected = cswaConstants.getLegacyDepts(form, rr[8], rr[38])
        objstatuses, selected = cswaConstants.getObjectStatuses(form, rr[8], rr[37])
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname"><input class="objname" type="text" name="onm.%s" value="%s"></td>
<td class="veryshortinput"><input class="veryshortinput" type="text" name="ocn.%s" value="%s"></td>
<td>
<input type="hidden" name="oox.%s" value="%s"><input type="hidden" name="csid.%s" value="%s">
%s</td>
<td>%s</td>
<td><input class="xspan" type="text" size="40" name="cp.%s" value="%s"></td>
<td>%s</td>
<td>%s</td>
</tr>""" % (link, html.escape(rr[3], True),
            rr[8], html.escape(rr[4], True),
            rr[8], rr[5],
            rr[8], html.escape(rr[3], True), rr[8], rr[8],
            objtypes, collmans,
            rr[8], html.escape(rr[6], True),
            legacydepartments,
            objstatuses)
    elif fieldSet == 'collection':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<input type="hidden" name="oox.%s" value="%s">
<td class="objname"><input type="hidden" name="onm.%s" value="">%s</td>
<input type="hidden" name="clnx.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<td><input class="xspan" type="text" size="45" name="cln.%s" value="%s"></td>
</tr>""" % (link, html.escape(rr[1], True),
            rr[2], html.escape(rr[1], True),
            rr[2], html.escape(rr[3], True),
            rr[2], rr[22],
            rr[2], rr[2],
            rr[2], html.escape(rr[8], True))
    elif fieldSet == 'placeanddate':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<td class="objname"><input type="hidden" name="onm.%s" value="">%s</td>
<td><input class="xspan" type="text" size="45" name="vfcp.%s" value="%s"></td>
<td><input class="xspan" type="text" size="45" name="dcol.%s" value="%s"></td>
</tr>""" % (
        link, html.escape(rr[3], True),
        rr[8], html.escape(rr[3], True),
        rr[8], rr[8],
        rr[8], html.escape(rr[4], True),
        rr[8], html.escape(rr[28], True),
        rr[8], html.escape(rr[29], True))
    elif fieldSet == 'dates':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<input type="hidden" name="csid.%s" value="%s">
<td class="objname"><input type="hidden" name="onm.%s" value="">%s</td>
<td><input class="xspan" type="text" size="20" name="dprd.%s" value="%s"></td>
<td><input class="xspan" type="text" size="20" name="dcol.%s" value="%s"></td>
<td><input class="xspan" type="text" size="20" name="ddep.%s" value="%s"></td>
<td class="zcell"><textarea cols="78" rows="5" name="bdx.%s">%s</textarea></td>
</tr>""" % (
        link, html.escape(rr[3], True), rr[8], rr[8], rr[8], html.escape(rr[4], True),
        rr[8], html.escape(rr[32], True),
        rr[8], html.escape(rr[29], True),
        rr[8], html.escape(rr[34], True),
        rr[8], html.escape(rr[15], True))
    elif fieldSet == 'places':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<td class="objname"><input type="hidden" name="onm.%s" value="">%s</td>
<td><input class="xspan" type="text" size="45" name="vfcp.%s" value="%s"></td>
<td><input class="xspan" type="text" size="45" name="cp.%s" value="%s"></td>
<td><input class="xspan" type="text" size="45" name="pp.%s" value="%s"></td>
<td><input class="xspan" type="text" size="45" name="pd.%s" value="%s"></td>
</tr>""" % (
        link, html.escape(rr[3], True),
        rr[8], html.escape(rr[3], True),
        rr[8], rr[8],
        rr[8], html.escape(rr[4], True),
        rr[8], html.escape(rr[28], True),
        rr[8], html.escape(rr[6], True),
        rr[8], html.escape(rr[31], True),
        rr[8], html.escape(rr[35], True))
    elif fieldSet == 'mattax':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<td class="objname"><input type="hidden" name="onm.%s" value="">%s</td>
<td><input class="xspan" type="text" size="45" name="ma.%s" value="%s"></td>
<td><input class="xspan" type="text" size="45" name="ta.%s" value="%s"></td>
<td class="zcell"><textarea cols="78" rows="5" name="bdx.%s">%s</textarea></td>
</tr>""" % (link, html.escape(rr[3], True),
            rr[8], html.escape(rr[3], True),
            rr[8], rr[8],
            rr[8], html.escape(rr[4], True),
            rr[8], html.escape(rr[30], True),
            rr[8], html.escape(rr[33], True),
            rr[8], html.escape(rr[15], True))
    # ucjeps fieldset
    elif fieldSet == 'student':
        return """<tr>
    <td class="objno"><a target="cspace" href="%s">%s</a></td>
    <input type="hidden" name="oox.%s" value="%s">
    <input type="hidden" name="csid.%s" value="%s">
    <td><input class="xspan" type="text" size="36" name="ta.%s" value="%s"></td>
    <td><input class="xspan" type="text" size="36" name="cn.%s" value="%s"></td>
    <td><input class="xspan" type="text" size="36" name="st.%s" value="%s"></td>
    <td><input class="xspan" type="text" size="36" name="co.%s" value="%s"></td>
    <td><input class="xspan" type="text" size="10" name="pc.%s" value="%s"></td>
    <td><a href="/%s/media/%s" target="fullimage">View Media</a></td>
    <!-- td class="zcell"><textarea cols="78" rows="5" name="bdx.%s">%s</textarea></td -->
    </tr>""" % (link3, html.escape(rr[1], True),
                rr[0], html.escape(rr[1], True),
                rr[0], rr[0],
                rr[0], html.escape(rr[2], True),
                rr[0], html.escape(rr[4], True),
                rr[0], html.escape(rr[6], True),
                rr[0], html.escape(rr[8], True),
                rr[0], html.escape(rr[28], True),
                institution, html.escape(rr[1], True),
                rr[0], html.escape(rr[10], True))
    elif fieldSet == 'fullmonty':
        collmans, selected = cswaConstants.getCollMan(form, rr[8], rr[27])
        objstatuses, selected = cswaConstants.getObjectStatuses(form, rr[8], rr[37])
        objecttypes, selected = cswaConstants.getObjType(form, rr[8], rr[26])
        altnumtypes, selected = cswaConstants.getAltNumTypes(form, rr[8], rr[19])
        legacydepartments, selected = cswaConstants.getLegacyDepts(form, rr[8], rr[38])
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<td class="objname"><input class="xspan" type="text" name="onm.%s" value="%s"></td>
<td>

<table>

<tr class="monty">

<td>Count and Count Note<br/>
<input class="xspan" type="text" size="10" name="ocn.%s" value="%s">
<input class="xspan" type="text" size="20" name="ctn.%s" value="%s"></td>
</td>

<td>Cultural Group<br/>
<input class="xspan" type="text" size="45" name="cg.%s" value="%s"></td>

<td>Ethnographic File Code<br/>
<input class="xspan" type="text" size="45" name="fc.%s" value="%s"></td></td>

</tr>

<tr class="monty">

<td>Alt Num<br/>
<input class="xspan" type="text" size="45" name="anm.%s" value="%s"></td>

<td>Alt Num Type<br/>
%s</td>

<td>Field Collector<br/>
<input class="xspan" type="text" size="45" name="cl.%s" value="%s"></td>

</tr>

<tr class="monty">

<td>Object type<br/>
%s</td>

<td>Production person<br/>
<input class="xspan" type="text" size="45" name="pe.%s" value="%s"></td>

<td>Object Status<br/>
%s
</td>

</tr>

<tr class="monty">

<td>Date collected<br/>
<input class="xspan" type="text" size="45" name="dcol.%s" value="%s"></td>

<td>Production date<br/>
<input class="xspan" type="text" size="45" name="dprd.%s" value="%s"></td>

<td>Date depicted<br/>
<input class="xspan" type="text" size="45" name="ddep.%s" value="%s"></td>

</tr>

<tr class="monty">

<td>Materials<br/>
<input class="xspan" type="text" size="45" name="ma.%s" value="%s"></td>

<td>Taxon<br/>
<input class="xspan" type="text" size="45" name="ta.%s" value="%s"></td>

<td>Verbatim field collection place<br/>
<input class="xspan" type="text" size="45" name="vfcp.%s" value="%s"></td>

</tr>

<tr class="monty">

<td>Field collection place<br/>
<input class="xspan" type="text" size="45" name="cp.%s" value="%s"></td>

<td>Production Place<br/>
<input class="xspan" type="text" size="45" name="pp.%s" value="%s"></td>

<td>Place depicted<br/>
<input class="xspan" type="text" size="45" name="pd.%s" value="%s"></td>

</tr>

<tr>

<td>Collection Manager<br/>
%s
</td>

<td colspan="2">Legacy Department<br/>
%s
</td></tr>


<tr>
<td colspan="10">Brief Description<br/>
<textarea cols="130" rows="5" name="bdx.%s">%s</textarea>
</td>
</tr>

</table>

</td>
</tr>""" % (
        link, html.escape(rr[3], True),
        rr[8], html.escape(rr[3], True),
        rr[8], rr[8],
        rr[8], html.escape(rr[4], True),
        rr[8], rr[5],
        rr[8], html.escape(rr[25], True),
        rr[8], html.escape(rr[7], True),
        rr[8], html.escape(rr[9], True),
        rr[8], html.escape(rr[18], True),
        altnumtypes,
        rr[8], html.escape(rr[16], True),
        objecttypes,
        rr[8], html.escape(rr[36], True),
        objstatuses,
        rr[8], html.escape(rr[29], True),
        rr[8], html.escape(rr[32], True),
        rr[8], html.escape(rr[34], True),
        rr[8], html.escape(rr[30], True),
        rr[8], html.escape(rr[33], True),
        rr[8], html.escape(rr[28], True),
        rr[8], html.escape(rr[6], True),
        rr[8], html.escape(rr[31], True),
        rr[8], html.escape(rr[35], True),
        collmans,
        legacydepartments,
        rr[8], html.escape(rr[15], True)
        )


def setRefnames(refNames2find, fieldset, form, config, index):

    if fieldset in ['namedesc', 'fullmonty']:
        pass
    if fieldset in ['registration', 'fullmonty']:
        if not form.get('cl.' + index) in refNames2find:
            refNames2find[form.get('cl.' + index)] = cswaDB.getrefname('collectionobjects_common_fieldcollectors', form.get('cl.' + index), config)
    if fieldset in ['keyinfo', 'fullmonty']:
        if not form.get('cp.' + index) in refNames2find:
            refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
        if not form.get('cg.' + index) in refNames2find:
            refNames2find[form.get('cg.' + index)] = cswaDB.getrefname('concepts_common', form.get('cg.' + index), config)
        if not form.get('fc.' + index) in refNames2find:
            refNames2find[form.get('fc.' + index)] = cswaDB.getrefname('concepts_common', form.get('fc.' + index), config)
    if fieldset in ['hsrinfo', 'fullmonty']:
        if not form.get('cp.' + index) in refNames2find:
            refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
    if fieldset in ['places', 'fullmonty']:
        if not form.get('pp.' + index) in refNames2find:
            refNames2find[form.get('pp.' + index)] = cswaDB.getrefname('places_common', form.get('pp.' + index), config)
        if not form.get('cp.' + index) in refNames2find:
            refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
        if not form.get('pd.' + index) in refNames2find:
            refNames2find[form.get('pd.' + index)] = cswaDB.getrefname('places_common', form.get('pd.' + index), config)
    if fieldset in ['objtypecm', 'fullmonty']:
        if not form.get('cm.' + index) in refNames2find:
            refNames2find[form.get('cm.' + index)] = cswaDB.getrefname('persons_common', form.get('cm.' + index), config)
        if not form.get('cp.' + index) in refNames2find:
            refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
    if fieldset in ['student']:
        if not form.get('ta.' + index) in refNames2find:
            refNames2find[form.get('ta.' + index)] = cswaDB.getrefname('taxon_common', form.get('ta.' + index), config)
        if not form.get('cn.' + index) in refNames2find:
            refNames2find[form.get('cn.' + index)] = cswaDB.findvocabnames('fieldloccountry', form.get('cn.' + index), config)
        if not form.get('st.' + index) in refNames2find:
            refNames2find[form.get('st.' + index)] = cswaDB.findvocabnames('fieldlocstate', form.get('st.' + index), config)
        if not form.get('co.' + index) in refNames2find:
            refNames2find[form.get('co.' + index)] = cswaDB.findvocabnames('fieldloccounty', form.get('co.' + index), config)
    if fieldset in ['fullmonty', 'mattax']:
        if not form.get('pe.' + index) in refNames2find:
            refNames2find[form.get('pe.' + index)] = cswaDB.getrefname('persons_common', form.get('pe.' + index), config)
        if not form.get('ma.' + index) in refNames2find:
            refNames2find[form.get('ma.' + index)] = cswaDB.getrefname('concepts_common', form.get('ma.' + index), config)
        if not form.get('ta.' + index) in refNames2find:
            refNames2find[form.get('ta.' + index)] = cswaDB.getrefname('taxon_common', form.get('ta.' + index), config)

    return refNames2find
