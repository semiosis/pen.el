# SPDX-License-Identifier: CECILL-2.1

# Check that required packages are installed:
csvp = Base.find_package("CSV") == nothing
delimp = Base.find_package("DelimitedFiles") == nothing
pipep = Base.find_package("Pipe") == nothing
if any([csvp, delimp, pipep])
    using Pkg
    Pkg.add("CSV")
    Pkg.add("DelimitedFiles")
    Pkg.add("Pipe")
end

# Load required packages:
using CSV
using DelimitedFiles
using Pipe
using Suppressor

# Perso function to write Julia objects into CSV files:
function ob_ess_julia_csv_write(filename, bodycode, has_header)
    CSV.write(filename, bodycode, delim = "\t", writeheader = has_header);
end

function ob_ess_julia_write(bodycode::Any, filename::Any, has_header::Any)
    try
        ob_ess_julia_csv_write(filename, bodycode, has_header);
    catch err
        if isa(err, ArgumentError) | isa(err, MethodError)
            writedlm(filename, bodycode)
        end
    end
end

# Specific Windows stuff:
# (Contribution on GitHub by @fkgruber:
# https://github.com/frederic-santos/ob-ess-julia/issues/1#issuecomment-707433134
# )
if Sys.iswindows()
    println("In startup script")
    using Base: stdin, stdout, stderr
    using REPL.Terminals: TTYTerminal
    using REPL: BasicREPL, run_repl
    using DelimitedFiles
    run_repl(BasicREPL(TTYTerminal("emacs",stdin,stdout,stderr)))
    println("Finished initial startup")
end

# Contribution from Julia discourse:
# https://discourse.julialang.org/t/redirect-output-and-error-to-a-file/58908/5?u=fsantos
# Thanks to @FPGro
struct CopyToREPL <: AbstractDisplay
	io::IO
	copyto::AbstractDisplay
	insertnewlines::Bool
end

import Base: flush, close, display, displayable 

flush(d::CopyToREPL) = flush(d.io)
close(d::CopyToREPL) = close(d.io) # not the copyto display, we don't want to tear it down too

display(d::CopyToREPL, @nospecialize x) = display(d, MIME"text/plain"(), x)
display(d::CopyToREPL, M::MIME"text/plain", @nospecialize x) = _display(d, M, x)
function _display(d::CopyToREPL, M, @nospecialize x)
	show(d.io, M, x)
	d.insertnewlines && println(d.io)
	# you may insert a flush(d.io) here if you want to be able to kill the window without loosing content
	show(d.copyto, M, x)
end

displayable(d::CopyToREPL, M::MIME) = istextmime(M)
# it's probably better not to catch every MIME, idk
#function display(d::CopyToREPL, M::MIME, @nospecialize x)
#    displayable(d, M) || throw(MethodError(display, (d, M, x)))
#    _display(d.io, M, x)
#end

function gethighesttextdisplay()
	displays = Base.Multimedia.displays
	message = "Probing displays!" 
	# because we need to find the last display that actually outputs text 
	# or we may end up backing up to a plotting pane or so. There may be a better way to do this.
	for i = length(displays):-1:1
        if Base.Multimedia.xdisplayable(displays[i], message)
            try
                display(displays[i], message)
				return displays[i]
            catch e
                isa(e, MethodError) && (e.f === display || e.f === show) ||
                    rethrow()
            end
        end
    end
    error("No text display found, that's weird.")
end

function pophighestcopyto()
	displays = Base.Multimedia.displays
	for i = length(displays):-1:1
        if displays[i] isa CopyToREPL
            return splice!(displays, i)
        end
    end
    throw(KeyError(CopyToREPL))
end

function startREPLcopy(noIO; append = false)
	io = open(noIO, write = true, append = append)
	startREPLcopy(io)
end

stdoutbackup = []

function startREPLcopy(io::IO; insertnewlines = true)
	# insertnewlines because show(...) usually doesn't insert newlines after display,
	# so the output is kinda mashed together. There may be cleaner way to do this.
	backupdisplay = gethighesttextdisplay()
	cpdisplay = CopyToREPL(io, backupdisplay, insertnewlines)
	@info "Started copying REPL output to the specified location!"
	pushdisplay(cpdisplay)
	# TODO: It would be better to check here if the stdout hadn't been redirected before
	# So technically, this may snatch a stdout and display more than the REPL
	push!(stdoutbackup, Base.stdout)
	Base.redirect_stdout(io) 
	# TODO I think this does only work for IOStreams, so maybe unwrap contexts and such
	# TODO: may or may not be desirable to handle stderr
	nothing
end

function endREPLcopy()
	cpdisplay = try
		pophighestcopyto()
	catch e
		isa(e, KeyError) || rethrow()
		@warn "Couldn't stop copying the REPL output because it wasn't even started."
	end
	flush(cpdisplay)
	oldstdout = pop!(stdoutbackup)
	Base.redirect_stdout(oldstdout)
	close(cpdisplay)
	@info "Copying of REPL output stopped!"
	nothing
end
