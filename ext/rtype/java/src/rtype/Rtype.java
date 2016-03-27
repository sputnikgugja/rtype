package rtype;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyProc;
import org.jruby.RubyRegexp;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyModule(name="Rtype")
public class Rtype {
	public static Ruby ruby;
	public static RubyModule rtype;
	public static RubyModule rtypeBehavior;
	public static RubyClass rtypeBehaviorBase;
	public static RubyClass rtypeArgumentTypeError;
	public static RubyClass rtypeTypeSignatureError;
	public static RubyClass rtypeReturnTypeError;
	
	public static RubyClass symbol;
	public static RubyClass regexp;
	public static RubyClass array;
	public static RubyClass trueClass;
	public static RubyClass falseClass;
	public static RubyClass range;
	public static RubyClass proc;
	
	public static void init(Ruby ruby) {
		Rtype.ruby = ruby;
		
		rtype = ruby.defineModule("Rtype");
		rtypeBehavior = ruby.defineModuleUnder("Behavior", rtype);
		RubyClass object = ruby.getObject();
		rtypeBehaviorBase = ruby.defineClassUnder("Base", object, object.getAllocator(), rtypeBehavior);
		
		RubyClass argError = ruby.getArgumentError();
		rtypeArgumentTypeError = ruby.defineClassUnder("ArgumentTypeError", argError, argError.getAllocator(), rtype);
		rtypeTypeSignatureError = ruby.defineClassUnder("TypeSignatureError", argError, argError.getAllocator(), rtype);
		
		RubyClass stdError = ruby.getStandardError();
		rtypeReturnTypeError = ruby.defineClassUnder("ReturnTypeError", stdError, stdError.getAllocator(), rtype);
		
		symbol = ruby.getSymbol();
		regexp = ruby.getRegexp();
		array = ruby.getArray();
		trueClass = ruby.getTrueClass();
		falseClass = ruby.getFalseClass();
		range = ruby.getRange();
		proc = ruby.getProc();
		
		rtype.defineAnnotatedMethods(Rtype.class);
	}
	
	@JRubyMethod(name = "valid?")
	public static IRubyObject valid(ThreadContext context, IRubyObject self,
			IRubyObject expected, IRubyObject value) {
		return RubyBoolean.newBoolean(ruby, validInternal(context, self, expected, value));
	}
	
	public static boolean validInternal(ThreadContext context, IRubyObject self,
			IRubyObject expected, IRubyObject value) {
		if(expected.isClass()
		|| expected.isModule()) {
			return ((RubyModule) expected).isInstance(value);
		}
		else if( symbol.isInstance(expected) ) {
			return value.respondsTo( expected.asString().asJavaString() );
		}
		else if( regexp.isInstance(expected) ) {
			IRubyObject result = ((RubyRegexp) expected).match_m( context, value.asString() );
			return !result.isNil();
		}
		else if( array.isInstance(expected) ) {
			if( !array.isInstance(value) ) {
				return false;
			}
			
			RubyArray expt = (RubyArray) expected;
			RubyArray v = (RubyArray) value;
			int exptLen = expt.getLength();
			
			if(exptLen != v.getLength()) {
				return false;
			}
			else {
				for(int i = 0; i < exptLen; i++) {
					IRubyObject exptEl = expt.entry(i);
					IRubyObject vEl = v.entry(i);
					boolean isValid = validInternal(context, self, exptEl, vEl);
					if(!isValid) {
						return false;
					}
				}
				return true;
			}
		}
		else if(trueClass.isInstance(expected)) {
			return value.isTrue();
		}
		else if(falseClass.isInstance(expected)) {
			return !value.isTrue();
		}
		else if(range.isInstance(expected)) {
			IRubyObject result = expected.callMethod(context, "include?", value);
			return result.isTrue();
		}
		else if(proc.isInstance(expected)) {
			RubyProc expectedProc = (RubyProc) expected;
			IRubyObject result = expectedProc.call(context, new IRubyObject[]{value});
			return result.isTrue();
		}
		else if(rtypeBehaviorBase.isInstance(expected)) {
			IRubyObject result = expected.callMethod(context, "valid?", value);
			return result.isTrue();
		}
		else {
			String msg = "Invalid type signature: Unknown type behavior " + expected.asString().asJavaString();
			RubyException exp = new RubyException(ruby, rtypeTypeSignatureError, msg);
			throw new RaiseException(exp);
		}
	}
	
	@JRubyMethod(name="assert_arguments_type")
	public static void assertArgumentsType(ThreadContext context, IRubyObject self,
			IRubyObject expectedArgs, IRubyObject args) {
		RubyArray rExptArgs = (RubyArray) expectedArgs;
		RubyArray rArgs = (RubyArray) args;
		int len = rExptArgs.getLength();
		
		for(int i = 0; i < len; i++) {
			IRubyObject e = rExptArgs.entry(i);
			IRubyObject v = rArgs.entry(i);
			
			if(!e.isNil()) {
				if(!validInternal(context, self, e, v)) {
					String msg = rtype.callMethod("arg_type_error_message", new RubyFixnum(ruby, i), e, v).asJavaString();
					RubyException exp = new RubyException(ruby, rtypeArgumentTypeError, msg);
					throw new RaiseException(exp);
				}
			}
		}
	}
	
	@JRubyMethod(name="assert_arguments_type_with_keywords", required=4)
	public static void assertArgumentsTypeWithKeywords(ThreadContext context, IRubyObject self, IRubyObject[] arguments) {
		IRubyObject expectedArgs = arguments[0];
		IRubyObject args = arguments[1];
		IRubyObject expectedKwargs = arguments[2];
		IRubyObject kwargs = arguments[3];
		
		assertArgumentsType(context, self, expectedArgs, args);
		
		RubyHash exptHash = (RubyHash) expectedKwargs;
		RubyHash hash = (RubyHash) kwargs;
		RubyArray keys = hash.keys();
		int len = keys.getLength();
		
		for(int i = 0; i < len; i++) {
			IRubyObject key = keys.entry(i);
			IRubyObject e = exptHash.op_aref(context, key);
			if(!e.isNil()) {
				IRubyObject v = hash.op_aref(context, key);
				if(!validInternal(context, self, e, v)) {
					String msg = rtype.callMethod("kwarg_type_error_message", key, e, v).asJavaString();
					RubyException exp = new RubyException(ruby, rtypeArgumentTypeError, msg);
					throw new RaiseException(exp);
				}
			}
		}
	}
	
	@JRubyMethod(name="assert_return_type")
	public static void assertReturnType(ThreadContext context, IRubyObject self,
			IRubyObject expected, IRubyObject result) {
		if(expected.isNil()) {
			if(!result.isNil()) {
				String msg = "for return:\n" + rtype.callMethod("type_error_message", expected, result).asJavaString();
				RubyException exp = new RubyException(ruby, rtypeReturnTypeError, msg);
				throw new RaiseException(exp);
			}
		}
		else {
			if(!validInternal(context, self, expected, result)) {
				String msg = "for return:\n" + rtype.callMethod("type_error_message", expected, result).asJavaString();
				RubyException exp = new RubyException(ruby, rtypeReturnTypeError, msg);
				throw new RaiseException(exp);
			}
		}
	}
}