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
	public static String JAVA_EXT_VERSION = "0.6.7";
	
	public static Ruby ruby;
	public static RubyModule rtype;
	public static RubyModule rtypeBehavior;
	public static RubyClass rtypeBehaviorBase;
	public static RubyClass rtypeArgumentTypeError;
	public static RubyClass rtypeTypeSignatureError;
	public static RubyClass rtypeReturnTypeError;
	
	public static RubyClass symbol;
	public static RubyClass regexp;
	public static RubyClass hash;
	public static RubyClass array;
	public static RubyClass trueClass;
	public static RubyClass falseClass;
	public static RubyClass range;
	public static RubyClass proc;
	
	public static RubyBoolean qtrue;
	public static RubyBoolean qfalse;
	
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
		hash = ruby.getHash();
		array = ruby.getArray();
		trueClass = ruby.getTrueClass();
		falseClass = ruby.getFalseClass();
		range = ruby.getRange();
		proc = ruby.getProc();
		
		qtrue = ruby.getTrue();
		qfalse = ruby.getFalse();
		
		rtype.defineAnnotatedMethods(Rtype.class);
		rtype.defineConstant("JAVA_EXT_VERSION", ruby.newString(JAVA_EXT_VERSION));
	}
	
	@JRubyMethod(name = "valid?")
	public static IRubyObject valid(ThreadContext context, IRubyObject self,
			IRubyObject expected, IRubyObject value) {
		return validInternal(context, self, expected, value) ? qtrue : qfalse;
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
		else if( hash.isInstance(expected) ) {
			if( !hash.isInstance(value) ) {
				return false;
			}
			RubyHash expt = (RubyHash) expected;
			RubyHash v = (RubyHash) value;
			RubyArray exptKeys = expt.keys();
			RubyArray vKeys = v.keys();
			if(!exptKeys.equals(vKeys)) {
				return false;
			}
			
			for(int i = 0; i < exptKeys.size(); i++) {
				IRubyObject exptKey = exptKeys.entry(i);
				IRubyObject exptVal = expt.op_aref(context, exptKey);
				IRubyObject vVal = v.op_aref(context, exptKey);
				if( !validInternal(context, self, exptVal, vVal) ) {
					return false;
				}
			}
			return true;
		}
		else if( array.isInstance(expected) ) {
			RubyArray expt = (RubyArray) expected;
			int exptLen = expt.getLength();
			for(int i = 0; i < exptLen; i++) {
				IRubyObject exptEl = expt.entry(i);
				boolean isValid = validInternal(context, self, exptEl, value);
				if(isValid) {
					return true;
				}
			}
			return false;
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
		else if(expected.isNil()) {
			return value.isNil();
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
		int e_len = rExptArgs.getLength();
		int len = rArgs.getLength();
		
		for(int i = 0; i < len; i++) {
			if(i >= e_len) break;
			
			IRubyObject e = rExptArgs.entry(i);
			IRubyObject v = rArgs.entry(i);
			
			if(!validInternal(context, self, e, v)) {
				String msg = rtype.callMethod("arg_type_error_message", new RubyFixnum(ruby, i), e, v).asJavaString();
				RubyException exp = new RubyException(ruby, rtypeArgumentTypeError, msg);
				throw new RaiseException(exp);
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
		RubyHash vHash = (RubyHash) kwargs;
		RubyArray keys = vHash.keys();
		int len = keys.getLength();
		
		for(int i = 0; i < len; i++) {
			IRubyObject key = keys.entry(i);
			if(exptHash.containsKey(key)) {
				IRubyObject e = exptHash.op_aref(context, key);
				IRubyObject v = vHash.op_aref(context, key);
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
		if(!validInternal(context, self, expected, result)) {
			String msg = "for return:\n" + rtype.callMethod("type_error_message", expected, result).asJavaString();
			RubyException exp = new RubyException(ruby, rtypeReturnTypeError, msg);
			throw new RaiseException(exp);
		}
	}
}
