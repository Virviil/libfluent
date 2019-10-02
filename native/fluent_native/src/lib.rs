#[macro_use]
extern crate rustler;

use rustler::{Encoder, Env, Error, Term, TermType};
use rustler::ResourceArc;
use std::sync::RwLock;

use fluent::{FluentBundle, FluentValue, FluentResource, FluentArgs};
use unic_langid::LanguageIdentifier;

mod atoms {
    rustler_atoms! {
        atom ok;
        atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";

        atom bad_locale;
        atom bad_resource;
        atom bad_msg;
        atom no_value;
    }
}

struct Container {
	data: RwLock<FluentBundle<FluentResource>>,
}

fn on_init<'a>(env: Env<'a>, _load_info: Term<'a>) -> bool {
    resource_struct_init!(Container, env);
    true
}

rustler::rustler_export_nifs! {
    "Elixir.Fluent.Native",
    [
        ("init", 1, init),
        ("with_resource", 2, with_resource),
        ("format_pattern", 3, format_pattern),
        ("assert_locale", 1, assert_locale),
    ],
    Some(on_init)
}

fn init<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let lang: String = args[0].decode()?;
    // Getting language
    let lang_id = match lang.parse::<LanguageIdentifier>() {
        Ok(lang_id) => lang_id,
        Err(_e) => return Ok((atoms::error(), (atoms::bad_locale(), lang)).encode(env))
    };
    // Initializing bundle
    let bundle = FluentBundle::new(&[lang_id]);
    let bundle = Container {
        data: RwLock::new(bundle),
    };

    Ok((atoms::ok(), ResourceArc::new(bundle)).encode(env))
}

fn with_resource<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let container: ResourceArc<Container> = args[0].decode()?;
    let source: String = args[1].decode()?;

    // Initializing resource
    let resource = match FluentResource::try_new(source) {
        Ok(resource) => resource,
        Err((_resource, _error)) => {
            return Ok(
                (atoms::error(), atoms::bad_resource()).encode(env)
            )
        }
    };

    // Locking bundle to write
    let mut bundle = container.data.write().unwrap();
    match bundle.add_resource(resource) {
        Ok(_value) => Ok(atoms::ok().encode(env)),
        Err(_e) => return Ok((atoms::error(), atoms::bad_resource()).encode(env))
    }
}

fn format_pattern<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let container: ResourceArc<Container> = args[0].decode()?;
    let msg_id: String = args[1].decode()?;
    let arg_ids: Vec<(rustler::types::Atom, Term)> = args[2].decode()?;

    // Reconfiguring args
    let arg_ids: Vec<(String, FluentValue)> = arg_ids.into_iter().map(|(key, value)| {
        let fluent_value: FluentValue = match &value.get_type() {
            TermType::Binary => {
                match value.decode::<String>() {
                    Ok(string) => FluentValue::from(string),
                    Err(_e) => panic!("Mismatched types")
                }
            },
            TermType::Number => {
                match value.decode::<f64>() {
                    Ok(float) => FluentValue::from(float),
                    Err(_e) => {
                        match value.decode::<i64>() {
                            Ok(integer) => FluentValue::from(integer),
                            Err(_e) => panic!("Mismatched types")
                        }
                    }
                }
            }
            _ => panic!("Mismatched types") // TODO: Add error handling
        };
        (format!("{:?}", key), fluent_value)
    }).collect();

    // Locking bundle to write
    let bundle = container.data.read().unwrap();

    // Getting message
    let msg = match bundle.get_message(&msg_id) {
        Some(msg) => msg,
        None => return Ok((atoms::error(), atoms::bad_msg()).encode(env))
    };

    // Getting args
    let mut args = FluentArgs::new();
    for (key, value) in &arg_ids {
        args.insert(key, value.clone());
    }

    // Getting errors
    let mut errors = vec![];

    // Formatting pattern
    let pattern = match msg.value {
        Some(value) => value,
        None => return Ok((atoms::error(), atoms::no_value()).encode(env))
    };

    let value = bundle.format_pattern(&pattern, Some(&args), &mut errors);

    Ok((atoms::ok(), value.into_owned()).encode(env))
}

fn assert_locale<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let lang: String = args[0].decode()?;
    // Getting language
    match lang.parse::<LanguageIdentifier>() {
        Ok(lang_id) => Ok((atoms::ok(), &lang_id.to_string()).encode(env)),
        Err(_e) => Ok((atoms::error(), (atoms::bad_locale(), lang)).encode(env))
    }
}
