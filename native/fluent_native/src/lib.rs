use rustler::ResourceArc;
use rustler::{Encoder, Env, Error, Term, TermType};
use std::sync::RwLock;

use fluent::bundle::FluentBundle;
use fluent::{FluentArgs, FluentResource, FluentValue};
use intl_memoizer::concurrent::IntlLangMemoizer;
use unic_langid::LanguageIdentifier;

mod atoms {
    rustler::atoms! {
        ok,
        error,

        bad_locale,
        bad_resource,
        bad_msg,
        no_value,

        use_isolating,
    }
}

struct Container {
    data: RwLock<FluentBundle<FluentResource, IntlLangMemoizer>>,
}

fn on_init<'a>(env: Env<'a>, _load_info: Term<'a>) -> bool {
    rustler::resource!(Container, env);
    true
}

#[rustler::nif]
fn init<'a>(
    env: Env<'a>,
    lang: String,
    bundle_init_keyword: Vec<(rustler::types::Atom, Term)>,
) -> Result<Term<'a>, Error> {
    // Getting language
    let lang_id = match lang.parse::<LanguageIdentifier>() {
        Ok(lang_id) => lang_id,
        Err(_e) => return Ok((atoms::error(), (atoms::bad_locale(), lang)).encode(env)),
    };
    // Initializing bundle
    let mut bundle = FluentBundle::new_concurrent(vec![lang_id]);

    // Setting different configs and flags
    for (key, value) in bundle_init_keyword {
        if key == atoms::use_isolating() {
            let use_isolating_value: bool = value.decode()?;
            bundle.set_use_isolating(use_isolating_value);
        }
    }
    let bundle = Container {
        data: RwLock::new(bundle),
    };

    Ok((atoms::ok(), ResourceArc::new(bundle)).encode(env))
}

#[rustler::nif]
fn with_resource(
    env: Env<'_>,
    container: ResourceArc<Container>,
    source: String,
) -> Result<Term<'_>, Error> {
    // Initializing resource
    let resource = match FluentResource::try_new(source) {
        Ok(resource) => resource,
        Err((_resource, _error)) => return Ok((atoms::error(), atoms::bad_resource()).encode(env)),
    };

    // Locking bundle to write
    let mut bundle = container.data.write().unwrap();
    match bundle.add_resource(resource) {
        Ok(_value) => Ok(atoms::ok().encode(env)),
        Err(_e) => return Ok((atoms::error(), atoms::bad_resource()).encode(env)),
    }
}

#[rustler::nif]
fn format_pattern<'a>(
    env: Env<'a>,
    container: ResourceArc<Container>,
    msg_id: String,
    arg_ids: Vec<(rustler::types::Atom, Term)>,
) -> Result<Term<'a>, Error> {
    // Reconfiguring args
    let arg_ids: Vec<(String, FluentValue)> = arg_ids
        .into_iter()
        .map(|(key, value)| {
            let fluent_value: FluentValue = match &value.get_type() {
                TermType::Binary => match value.decode::<String>() {
                    Ok(string) => FluentValue::from(string),
                    Err(_e) => panic!("Mismatched types"),
                },
                TermType::Number => match value.decode::<f64>() {
                    Ok(float) => FluentValue::from(float),
                    Err(_e) => match value.decode::<i64>() {
                        Ok(integer) => FluentValue::from(integer),
                        Err(_e) => panic!("Mismatched types"),
                    },
                },
                _ => panic!("Mismatched types"), // TODO: Add error handling
            };
            (format!("{:?}", key), fluent_value)
        })
        .collect();

    // Locking bundle to write
    let bundle = container.data.read().unwrap();

    // Getting message
    let msg = match bundle.get_message(&msg_id) {
        Some(msg) => msg,
        None => return Ok((atoms::error(), atoms::bad_msg()).encode(env)),
    };

    // Getting args
    let mut args = FluentArgs::new();
    for (key, value) in &arg_ids {
        args.set(key, value.clone());
    }

    // Getting errors
    let mut errors = vec![];

    // Formatting pattern
    let pattern = match msg.value() {
        Some(value) => value,
        None => return Ok((atoms::error(), atoms::no_value()).encode(env)),
    };

    let value = bundle.format_pattern(pattern, Some(&args), &mut errors);

    Ok((atoms::ok(), value.into_owned()).encode(env))
}

#[rustler::nif]
fn assert_locale(env: Env<'_>, lang: String) -> Result<Term<'_>, Error> {
    // Getting language
    match lang.parse::<LanguageIdentifier>() {
        Ok(lang_id) => Ok((atoms::ok(), &lang_id.to_string()).encode(env)),
        Err(_e) => Ok((atoms::error(), (atoms::bad_locale(), lang)).encode(env)),
    }
}

rustler::init!(
    "Elixir.Fluent.Native",
    [init, with_resource, format_pattern, assert_locale],
    load = on_init
);

#[cfg(test)]
mod test {
    use crate::*;

    fn assert_send_and_sync<T: Send + Sync + 'static>() {}

    #[test]
    fn it_is_send_and_sync() {
        assert_send_and_sync::<Container>();
    }
}
